class ClocksController < ApplicationController
  before_action :set_clock, only: [:show, :edit, :update, :destroy]
  before_filter :check_administrative_ip, except: [:new, :create]
  before_filter :check_admin_role, only: [:export, :check_sla]
  before_action :authenticate_user!


  # GET /export
  # GET /export.json
  def export
    @month=params[:date] ? Date.parse(params[:date]) : Date.today
    @from_date=@month.at_beginning_of_month
    @to_date=@month.at_end_of_month
    areas= User.uniq.pluck(:area).compact.uniq
    @result={}
    areas.each do |area|
      @result[area]=User.where(area: area).map do |user|
        user.report(@month)
      end
    end
    respond_to do |format|
      format.html { }
      format.xls do

        #render layout: false
        spreadsheet = StringIO.new
        new_book = Spreadsheet::Workbook.new
        Spreadsheet.client_encoding = 'UTF-8'
        new_book.create_worksheet :name => 'timesheet'
        sheet=new_book.worksheet(0)
        counter=0

        row_data=[""]
        (@from_date..@to_date).each{|date| row_data +=  [date.strftime("%A"), "", "", "", ""] }
        sheet.update_row counter+=1 ,  *row_data

        row_data=[]
        row_data << @from_date.month
        (@from_date..@to_date).each{|date| row_data +=  [date, "", "", "", ""] }
        row_data += [ "Totale Ore Lavorate", "Totale per Tipo"]
        sheet.update_row counter+=1 ,  *row_data

        row_data=[]
        @result.keys.sort.each do |area|
          row_data=[]
          row_data << area
          (@from_date..@to_date).each do |date|
            row_data += ["E.", "U.", "ore", "[+] o [-]", "Assenze"]
          end
          #row_data += [ "Totale Ore Lavorate", "Totale per Tipo"]
          sheet.update_row counter+=1 ,  *row_data
          @result[area].each do |user|
            row_data=[]
            row_data << user[:user]
            (@from_date..@to_date).each do |date|
              row_data <<  user[date.to_s][:check_in]
              row_data <<  user[date.to_s][:check_out]
              row_data <<  user[date.to_s][:worked_hours]
              row_data <<  user[date.to_s][:delta]
              row_data <<  user[date.to_s][:absence]

            end
            row_data <<  user[:tot_absence].round(2)
            row_data <<  user[:tot_hours].round(2)
            row_data <<  user[:tot_by_tipo]
            sheet.update_row counter+=1 ,  *row_data
          end
        end
        new_book.write spreadsheet
        send_data spreadsheet.string, :filename => "export.xls", :type =>  "application/vnd.ms-excel"
      end
    end


  end

  # GET /check_sla
  # GET /check_sla.json
  def check_sla
    @month=params[:date] ? Date.parse(params[:date]) : Date.today
    @from_date=@month.at_beginning_of_month
    @to_date=@month.at_end_of_month


    @cicles=(21-8)*4 #each 15 minute from 8 to 20
    areas= User.uniq.pluck(:area).compact.uniq
    @result={}
    areas.each do |area|
      @result[area]={}
      start=Time.parse("08:00:00",@from_date)
      @cicles.times do |i|
        utc_time=start.dup.utc
        checked_in  = Clock.joins(:user).where(users:{area:area}, date: (@from_date..@to_date)).where(["coalesce(tipo,'')='' and action = 'check_in' and Time(time) <= ?", utc_time.strftime("%H:%M")]).group(:date).count
        checked_out = Clock.joins(:user).where(users:{area:area}, date: (@from_date..@to_date)).where(["coalesce(tipo,'')='' and action = 'check_out' and Time(time) <= ?", utc_time.strftime("%H:%M")]).group(:date).count
        (@from_date..@to_date).each_with_index do |date, date_index|
          @result[area][start.strftime("%H:%M")] ||= []
          @result[area][start.strftime("%H:%M")][date_index] =  (checked_in[date].to_i-checked_out[date].to_i)
        end
        start=start.advance(minutes: 15)
      end
    end
    respond_to do |format|
      format.html { }
      format.xls do
        #render layout: false
        spreadsheet = StringIO.new
        new_book = Spreadsheet::Workbook.new
        Spreadsheet.client_encoding = 'UTF-8'
        @result.each_key do |area|
          counter=0
          next if area.to_s ==""
          name="CheckSla #{area.tableize[0..10]}"
          new_book.create_worksheet :name => name
          sheet=new_book.worksheet(name)
          sheet.update_row counter+=1 , "Area: #{area}" , "Mese :#{@from_date.month}"
          row_data=["WEEKDAY:"]
          row_data += (@from_date..@to_date).to_a.map{|d| d.strftime("%A")}
          sheet.update_row  counter +=1, *row_data
          row_data=[""]
          row_data += (@from_date..@to_date).to_a
          sheet.update_row  counter +=1, *row_data
          @result[area].each do |hh, values|
            #hh => "08:00", "08:15"
            row_data=[]
            row_data << hh
            puts values.inspect
            row_data += values
            #values.each do |dd,counters|
            #end
            sheet.update_row  counter+=1, *row_data

          end
        end
        new_book.write spreadsheet
        send_data spreadsheet.string, :filename => "check_sla.xls", :type =>  "application/vnd.ms-excel"
      end
    end
  end


  # GET /clocks
  # GET /clocks.json
  def index
    redirect_to url_for(action: :dashboard) if (current_user.is_camera? && !current_user.is_admin?)
    @clocks = Clock.all
  end


  # GET /clocks
  # GET /clocks.json
  def dashboard
    current_date=Date.today
    check_in  = Clock.joins(:user).where(action: "check_in", date: current_date).group(:area).count
    check_out = Clock.joins(:user).where(action: "check_out", date: current_date).group(:area).count
    check_out.each { |area,value| check_in[area]+=-value if check_in[area]}
    @clocks = check_in
    #@clocks = Clock.joins(:user).where(action: "check-in", date: current_date).group{|x| [x.user.area]}.count
  end

  # GET /clocks/1
  # GET /clocks/1.json
  def show
    redirect_to new_clock_url
  end

  # GET /clocks/new
  def new
    redirect_to url_for(action: :dashboard) if (current_user.is_camera? && !current_user.is_admin?)
    #@preset_ip=Setting.where(group: "ips", key: request.remote_ip).first
    @moment=Time.now.at_beginning_of_minute
    @clock = Clock.new(params[:clock].nil? ? {user_id:current_user.id} : clock_params)

  end

  #GET /clocks/1/edit
  def edit

  end

  # POST /clocks
  # POST /clocks.json
  def create
    clock_params[:message].strip!
    @clock = Clock.new(clock_params)

    if current_user.is_admin?
      @clock.date||=Date.today
    else
      @clock.date=Date.today
      @clock.user=current_user
    end

    @clock.time=Time.parse("#{params[:date][:hour]}:#{params[:date][:minute]}:00", @clock.date)
    @clock.ip=request.remote_ip
    #@clock.pin=params[:pin]
    @moment=@clock.time.localtime # Time.now.at_beginning_of_minute
    #@moment=@moment.advance(minutes: -(@moment.min % 5))
    respond_to do |format|
      if @clock.save
        message="Registrazione #{@clock.action} per #{@clock.user.username} alle #{@clock.time.localtime} avvenuta con successo."
        AdminMailer.timesheet(Date.today).deliver
        AdminMailer.confirm_mail(@clock.user, "#{message}\r\n#{@clock.message}").deliver

        format.html { redirect_to new_clock_url, notice: message }
        format.json { render :show, status: :created, location: @clock }
      else
        format.html { render :new }
        format.json { render json: @clock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clocks/1
  # PATCH/PUT /clocks/1.json
  def update
    params[:clock][:time]=Time.parse("#{params[:date][:hour]}:#{params[:date][:minute]}:00", @clock.date)
    respond_to do |format|
      if @clock.update(clock_params)
        format.html { redirect_to edit_clock_path(@clock), notice: 'Clock was successfully updated.' }
        format.json { render :show, status: :ok, location: @clock }
      else
        format.html { render :edit }
        format.json { render json: @clock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clocks/1
  # DELETE /clocks/1.json
  def destroy
    @clock.destroy
    respond_to do |format|
      format.html { redirect_to clocks_url, notice: 'Clock was successfully destroyed.' }
      format.json { head :no_content }
    end
    return
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_clock
      @clock = Clock.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def clock_params
      params.require(:clock).permit(:date, :tipo, :time, :user,:user_id,  :ip, :action, :message)
    end


end
