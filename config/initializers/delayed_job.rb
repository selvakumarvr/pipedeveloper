require 'delayed_job'

class DelayedJobLoggerPlugin < Delayed::Plugin

  callbacks do |lifecycle|

    lifecycle.around(:invoke_job) do |job, &block|
      logger.info "Running job", :running, job_to_hash(job)
      begin
        block.call(job)
        logger.info "Job success", :success, job_to_hash(job)
      rescue Exception => e
        # log and reraise
        logger.info "Job error: #{e.inspect}", :error, job_to_hash(job)
        raise e
      end
    end
  end

  def self.job_to_hash(job)
    payload = job.payload_object # Usually the Struct, but can be a PerformableObject also

    case payload
    when Struct
      {job_name: payload.class.name, args: payload.to_h }
    when Delayed::PerformableMethod
      {job_name: "#{payload.object.to_s}.#{payload.method_name.to_s}", args: payload.args.to_s}
    else
      {payload: payload.inspect}
    end
  end

  def self.logger
    @logger ||= SharetribeLogger.new(:delayed_job)
  end
end

Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 3.minutes # In order to recover from hanging DelayedDelta. Currently no jobs should be longer than 3min.
Delayed::Worker.default_priority = 5
Delayed::Worker.plugins << DelayedJobLoggerPlugin
