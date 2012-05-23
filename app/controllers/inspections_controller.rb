class InspectionsController < ApplicationController
  # GET /inspections
  # GET /inspections.json
  def index
    @inspections = Inspection.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @inspections }
    end
  end

  # GET /inspections/1
  # GET /inspections/1.json
  def show
    @inspection = Inspection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @inspection }
    end
  end

  # GET /inspections/new
  # GET /inspections/new.json
  def new
    @inspection = Inspection.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @inspection }
    end
  end

  # GET /inspections/1/edit
  def edit
    @inspection = Inspection.find(params[:id])
  end

  # POST /inspections
  # POST /inspections.json
  def create
    insp_params = params[:inspection]

    #@inspection = Inspection.find_by_property_id_and_start_and_end(insp_params[:property_id],
    #                                                              insp_params[:start], insp_params[:end])

    property = Property.find(insp_params[:property_id])
    matching_inspections = property.inspections.select { |i| i.start == insp_params[:start] and i.end == insp_params[:end] }

    #puts "MATCHING : #{matching_inspections}"
    #puts "SIZE: #{matching_inspections.size} (should never be > 1)"

    respond_to do |format|
      if matching_inspections.size > 0
        @inspection = matching_inspections[0]
        if @inspection.update_attributes(params[:inspection])
          format.html { redirect_to @inspection, notice: 'Inspection was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @inspection.errors, status: :unprocessable_entity }
        end
      else
        @inspection = Inspection.new(params[:inspection])
        if @inspection.save
          format.html { redirect_to @inspection, notice: 'Inspection was successfully created.' }
          format.json { render json: @inspection, status: :created, location: @inspection }
        else
          format.html { render action: "new" }
          format.json { render json: @inspection.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /inspections/1
  # PUT /inspections/1.json
  def update
    @inspection = Inspection.find(params[:id])

    respond_to do |format|
      if @inspection.update_attributes(params[:inspection])
        format.html { redirect_to @inspection, notice: 'Inspection was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @inspection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inspections/1
  # DELETE /inspections/1.json
  def destroy
    @inspection = Inspection.find(params[:id])
    @inspection.destroy

    respond_to do |format|
      format.html { redirect_to inspections_url }
      format.json { head :no_content }
    end
  end
end
