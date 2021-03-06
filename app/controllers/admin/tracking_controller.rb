class Admin::TrackingController < ApplicationController
  resource_controller

  def generate
    # Instanciate variable
    default_path = '/tmp/tracking/'

    # If the default_path isn t present
    unless File.directory?(default_path)
      # Create it
      FileUtils.mkdir_p default_path
    end

    # Retrieve the active shipment
    begin
      tmp_shipment = Shipment.find(params[:id])
    rescue
      tmp_shipment = nil
    end
    
    unless tmp_shipment.nil?
      case tmp_shipment.shipping_method.shipping_type.identifier
        when "tnt" then tracking = TrackingTnt.new(tmp_shipment)
        when "chronopost" then tracking = TrackingChronopost.new(tmp_shipment)
        when "colissimo" then tracking = TrackingChronopost.new(tmp_shipment)
      end

      unless tracking.nil?
        # Create Object File and write String Generated by TrackingEngine
        f = File.open("#{default_path}#{tracking.named_file}", 'w')
        f.write tracking.file
        f.close

        # Send the file
        send_file("#{f.path}", :type => "text/plain")
      end
    end
  end
end
