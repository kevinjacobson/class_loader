class ClassLoader::Watcher
  attr_accessor :paths, :interval

  def initialize monitor
    @monitor = monitor
    @paths, @files = [], {}
    @interval = 2
  end

  def stop
    return unless thread
    thread.kill
    @thread = nil
  end

  def start
    return if thread
    @thread = Thread.new do
      while true
        sleep interval
        check
      end
    end
  end

  def check
    monitor.synchronize do
      paths.each do |path|
        Dir.glob("#{path}/**/*.rb").each do |class_path|
          updated_at = File.mtime class_path
          if last_updated_at = files[class_path]
            if last_updated_at < updated_at
              class_file_name = class_path.sub "#{path}/", ''
              reload class_file_name
              files[class_path] = updated_at
            end
          else
            files[class_path] = updated_at
          end
        end
      end
    end
  end

  protected
    def reload file
      begin
        load file
        warn "file '#{file}' reloaded."
      rescue => e
        warn "can't reload '#{file}' file (#{e.message})!"
      end
    end

    attr_reader :files, :thread, :monitor
end