##
# ServerErrorLog provides logging functionality for handling and recording errors
# that occur within the chat server. It allows consistent error logging using a
# logger instance, ensuring that important error messages are captured for debugging
# and monitoring.
#
# This module is designed to:
# - Log generic errors that may occur during client connections, message handling,
#   or any other server operations.
# - Provide a simple and reusable interface for error logging across different parts
#   of the server.
#
# Key Method:
# - `log_generic_error`: Logs a detailed error message using the server's logger.
#
# This module helps maintain a clean and centralized approach to error handling, making it easier
# to debug issues and monitor server behavior.
module ServerErrorLog

  ##
  # Logs a generic error message to the server's logger.
  #
  # This method is designed to be called when an unexpected error occurs during
  # server operations. The error message is prefixed with `[GENERIC ERROR]` for
  # clarity and consistency in the logs.
  #
  # @param [StandardError] e The exception or error object to be logged.
  #
  # @return [void]
  def log_generic_error(e)
    @logger.error("[GENERIC ERROR]: #{e.message}")
  end
end