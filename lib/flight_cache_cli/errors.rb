
class FlightCacheCli
  class Error < StandardError; end
  class MissingToken < Error; end
  class ExistingFileError < Error; end
end
