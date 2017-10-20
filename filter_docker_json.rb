module Fluent
  class DockerJsonFilter < Filter
    Plugin.register_filter('docker_json', self)

    config_param :docker_log_key, :string, default: 'log'
    config_param :extract_json_log, :bool, default: false

    def configure(conf)
      super
    end

    def data(input)
      return input if input.is_a?(Hash) # return if already hash
      begin
        output = JSON.parse(input) if input[0] == '{' || input[0] == '['
        raise 'parse error' if output.nil?
        return output # return parsed hash
      rescue
        log.debug 'Input was not valid JSON.'
      end
      input # return original string if not JSON (or malformed)
    end

    def filter(_tag, _time, input)
      log.debug "Input: #{input}"
      output = data(input)
      if @extract_json_log && output.key?(@docker_log_key)
        log_data = data(output[@docker_log_key])
        log.debug "log_data: #{log_data}"
        if log_data.is_a?(Hash)
          output.merge!(log_data)
          output.delete(@docker_log_key)
        end
      end
      log.debug "Output: #{output}"
      output
    end
  end
end
