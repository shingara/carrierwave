# encoding: utf-8

module CarrierWave
  module Uploader
    module Store

      depends_on CarrierWave::Uploader::Callbacks
      depends_on CarrierWave::Uploader::Configuration
      depends_on CarrierWave::Uploader::Cache

      module ClassMethods

        ##
        # Sets the storage engine to be used when storing files with this uploader.
        # Can be any class that implements a #store!(CarrierWave::SanitizedFile) and a #retrieve!
        # method. See lib/carrierwave/storage/file.rb for an example. Storage engines should
        # be added to CarrierWave::Uploader::Base.storage_engines so they can be referred
        # to by a symbol, which should be more convenient
        #
        # If no argument is given, it will simply return the currently used storage engine.
        #
        # === Parameters
        #
        # [storage (Symbol, Class)] The storage engine to use for this uploader
        #
        # === Returns
        #
        # [Class] the storage engine to be used with this uploader
        #
        # === Examples
        #
        #     storage :file
        #     storage CarrierWave::Storage::File
        #     storage MyCustomStorageEngine
        #
        def storage(storage = nil)
          if storage.is_a?(Symbol)
            @storage = eval(storage_engines[storage])
          elsif storage
            @storage = storage
          elsif @storage.nil?
            # Get the storage from the superclass if there is one
            @storage = superclass.storage rescue nil
          end
          return @storage
        end
        alias_method :storage=, :storage

      end

      ##
      # Override this in your Uploader to change the filename.
      #
      # Be careful using record ids as filenames. If the filename is stored in the database
      # the record id will be nil when the filename is set. Don't use record ids unless you
      # understand this limitation.
      #
      # Do not use the version_name in the filename, as it will prevent versions from being
      # loaded correctly.
      #
      # === Returns
      #
      # [String] a filename
      #
      def filename
        @filename
      end

      ##
      # Calculates the path where the file should be stored. If +for_file+ is given, it will be
      # used as the filename, otherwise +CarrierWave::Uploader#filename+ is assumed.
      #
      # === Parameters
      #
      # [for_file (String)] name of the file <optional>
      #
      # === Returns
      #
      # [String] the store path
      #
      def store_path(for_file=filename)
        File.join(store_dir, full_filename(for_file))
      end

      ##
      # Stores the file by passing it to this Uploader's storage engine.
      #
      # If new_file is omitted, a previously cached file will be stored.
      #
      # === Parameters
      #
      # [new_file (File, IOString, Tempfile)] any kind of file object
      #
      def store!(new_file=nil)
        cache!(new_file) if new_file
        if @file and @cache_id
          with_callbacks(:store, new_file) do
            @file = storage.store!(@file)
            @cache_id = nil
          end
        end
      end

      ##
      # Retrieves the file from the storage.
      #
      # === Parameters
      #
      # [identifier (String)] uniquely identifies the file to retrieve
      #
      def retrieve_from_store!(identifier)
        with_callbacks(:retrieve_from_store, identifier) do
          @file = storage.retrieve!(identifier)
        end
      end

    private

      def full_filename(for_file)
        for_file
      end

      def storage
        @storage ||= self.class.storage.new(self)
      end

    end # Store
  end # Uploader
end # CarrierWave