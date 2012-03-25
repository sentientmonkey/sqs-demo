class JobsController < ApplicationController
  def create
    flash[:notice] = "Job created"
    msg = SleepJob.create(:length => 100)
    logger.debug msg.inspect
    redirect_to job_url(msg.id)
  end

  def index
  end

  def show
    job_id = params[:id]
    @status = {}
    #@status = Resque::Plugins::Status::Hash.get(job_id)
    respond_to do |format|
      format.html
      format.json { render :json => @status.to_json }
    end
  end
end
