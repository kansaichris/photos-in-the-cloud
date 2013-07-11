require 'thread'

##
# A parallel worker class
#
# @example Common usage
#  # Set up a job queue
#  queue = Queue.new
#
#  # Spin up a few workers
#  workers = []
#  (1..5).each do
#      workers << Worker.new(queue)
#  end
#
#  # Add some jobs to the queue
#  (1..50).each do |i|
#      queue << Proc.new { $stdout.print "Job ##{i}\n" }
#  end
#
#  # Shut down each of the workers once the queue is empty
#  sleep 0.1 until queue.empty?
#  workers.each { |worker| worker.shut_down }
class Worker

    # Initializes a new instance of the Worker class
    #
    # @param queue [Queue] the queue from which to process jobs
    #
    # @note This method automatically calls {#poll}.
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

    # Polls a queue for Proc objects to process
    #
    # @return [nil]
    #
    # @note You should never need to call this method manually because
    #       {#initialize} will call it for you automatically.
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

        nil
    end

    # Determines whether this worker has been asked to shut down
    #
    # @return [Boolean] `true` if this worker has been asked to shut down and
    #                   `false` otherwise
    def done?
        @exit_mutex.synchronize { @exit_state }
    end

    # Asks this worker to shut down
    #
    # @return [nil]
    def shut_down
        @exit_mutex.synchronize { @exit_state = true }
        @thread.join

        nil
    end

    # Determines whether this worker is idle
    #
    # A worker is considered to be idle if it is waiting for a job to be added
    # to the queue.
    #
    # @return [Boolean] `true` if this worker is currently idle and
    #                   `false` otherwise
    def idle?
        @idle_mutex.synchronize { @idle_state }
    end

    # Sets the value that will be returned by the {#idle?} method
    #
    # @param state [Boolean] the value that will be returned by the
    #                        {#idle?} method
    # @return [nil]
    def set_idle state
        @idle_mutex.synchronize { @idle_state = state }

        nil
    end

end
