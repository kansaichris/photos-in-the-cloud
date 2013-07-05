class Worker

    def initialize queue
        @queue = queue

        # Set the "idle state" (returned by the idle? method)
        # and a mutex for accessing it
        @idle_state = false
        @idle_mutex = Mutex.new

        # Set the "exit state" (returned by the done? method)
        # and a mutex for accessing it
        @exit_state = false
        @exit_mutex = Mutex.new

        poll
    end

    # Poll a queue for Proc objects to process
    def poll
        @thread = Thread.new do
            loop do
                while @queue.empty?
                    set_idle true
                    exit 0 if done?
                    sleep 1
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
