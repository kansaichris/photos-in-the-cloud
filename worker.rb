class Worker

    def initialize queue
        @idle_state = false
        @exit_state = false
        @queue = queue
        @idle_mutex = Mutex.new
        @exit_mutex = Mutex.new
        poll
    end

    # Pull a Proc from a queue and process it
    def poll
        @thread = Thread.new do
            loop do
                while @queue.empty?
                    set_idle true
                    sleep 1
                    exit 0 if done?
                end
                set_idle false
                job = @queue.pop
                job.call
            end
        end
    end

    def done?
        @exit_mutex.synchronize { @exit_state }
    end

    def shut_down
        @exit_mutex.synchronize { @exit_state = true }
        @thread.join
    end

    def idle?
        @idle_mutex.synchronize { @idle_state }
    end

    def set_idle state
        @idle_mutex.synchronize { @idle_state = state }
    end

end
