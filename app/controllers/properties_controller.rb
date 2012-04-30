class PropertiesController < ApplicationController
  # GET /properties
  # GET /properties.json
  def index
    if params[:external_id]
      @properties = Property.find_all_by_external_id(params[:external_id])
    else
      @properties = Property.all
    end

    # TODO why do I have to do this? why does the JSON not contain it?
    @properties.each { |p|
      p["inspections"] = p.inspections
    }

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: {properties: @properties, inspections: @inspections} }
      format.json { render json: @properties }
    end
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
    @property = Property.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @property }
    end
  end

  # GET /properties/new
  # GET /properties/new.json
  def new
    @property = Property.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @property }
    end
  end

  # GET /properties/1/edit
  def edit
    @property = Property.find(params[:id])
  end

  # POST /properties
  # POST /properties.json
  def create
    # update by external id
    prop_params = params["property"]
    puts "\n\nexternal id: #{prop_params[:external_id]}\n\n"

    # TODO throw error if external_id is null, and/or make it not nullable in db.

    @property = Property.find_by_external_id(prop_params[:external_id])

    # TODO push this logic to Property.create_or_update

    respond_to do |format|
      if @property != nil
        if @property.update_attributes(params[:property])
          format.html { redirect_to @property, notice: 'Property was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @property.errors, status: :unprocessable_entity }
        end
      else
        @property = Property.new(params[:property])
        if @property.save
          format.html { redirect_to @property, notice: 'Property was successfully created.' }
          format.json { render json: @property, status: :created, location: @property }
        else
          format.html { render action: "new" }
          format.json { render json: @property.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /properties/1
  # PUT /properties/1.json
  def update
    @property = Property.find(params[:id])

    respond_to do |format|
      if @property.update_attributes(params[:property])
        format.html { redirect_to @property, notice: 'Property was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /properties/1
  # DELETE /properties/1.json
  def destroy
    @property = Property.find(params[:id])
    @property.destroy

    respond_to do |format|
      format.html { redirect_to properties_url }
      format.json { head :no_content }
    end
  end
end
