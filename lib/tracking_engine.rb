class TrackingEngine
  attr_reader :file
  
  def initialize(xml_file_path_pattern, *args)
    # Extract options
    options_extract = args.extract_options!

    # Generate File with XML Pattern and Hash
    @file = process_fields(xml_file_path_pattern, options_extract)

  end

  # Concate Fields into a single text variable
  # Via XML Pattern Configuration File
  # hash : represent hash generated
  def process_fields(xml_file_path_pattern, options)
    # Return variable
    result = ''

    # If the configuration file is present
    if File.exist?(xml_file_path_pattern)
      
      # Read XML File
      xml = File.read(xml_file_path_pattern)

      # Parse XML File
      doc = Hpricot::XML(xml)

      # Process XML File
      (doc/:spree_tracking).each do |root|
        (root/:field).each_with_index do |field, ind|
          # Retrieve processing field
          processing_field = process_field(field, options[:fields_hash])

          # Log Message
          message = ''
          message = "'#{processing_field}' : #{processing_field.length}" unless processing_field.nil?
          p "FIELD #{ind} : #{message}"

          # Concate to the result
          result += processing_field unless processing_field.nil?
          
          # If there are separator value, add them
          result += options[:separator] if options.has_key?(:separator)
          
        end
        # If there are global settings
        unless (root/:global_settings).nil?
          # Retrieve global_settings part
          global_settings_field = (root/:global_settings)

          # Perform this part
          result = global_settings_processing(result, global_settings_field)
        end

      end
    end

    # Return the result
    result
  end

  def global_settings_processing(value, global_settings_field)
    # Instanciate
    result = value

    # Boolean test
    value_min_length = global_settings_field.at("min-length").inner_html.to_s unless global_settings_field.at("min-length").nil?
    value_max_length = global_settings_field.at("max-length").inner_html.to_s unless global_settings_field.at("max-length").nil?

    # If the value is constraint by a length condition
    if !value_min_length.nil? || !value_max_length.nil?
      # Define constraint part
      constraint_part = (global_settings_field/:pattern)

      # Unless value_min is nil?
      unless value_min_length.nil?
        # Kind of condition => MIN-LENGTH => PADDING MODE
        kind = 'min'

        # Define length condition
        length_condition = value_min_length
      else
        # Kind of condition => MAX-LENGTH => TRUNCATE MODE
        kind = 'max'

        # Define length condition
        length_condition = value_max_length
      end

      # Process constraint on the value
      result = process_constraint_length_condition(value,length_condition,constraint_part, kind)
    end

    # Return the value
    result
  end

  # Process field
  def process_field(field, hash_fields)
    # Instanciate variable
    result = ''

    # Retrieve name field
    name = field.at("/name").inner_html.to_s unless field.at("/name").nil?

    # 2 kind of field
    # PADDING with the only value property and (e.g. '-') and length properties
    # Field including name and (perhaps) value / min-length - max-length / padding property
    if name.nil?
      # First Case
      # Padding of VALUE while LENGTH times
      result = process_field_padding(field)
    else
      # Second Case
      # Including some property

      # Instanciate value
      value = field.at("/value").inner_html.to_s unless field.at("/value").nil?

      # If there aren t value
      if value.nil?
        # Retrieve Hash fields
        value = hash_fields["#{name}"]
      end

      # AT THIS POINT, WE HAVE STORE "VALUE" VALUE

      # NEXT STEP CHECK IF THERE ARE A CONSTRAINT PADDING PROPERTY

      # Boolean test
      value_min_length = field.at("min-length").inner_html.to_s unless field.at("min-length").nil?
      value_max_length = field.at("max-length").inner_html.to_s unless field.at("max-length").nil?

      # If the value is constraint by a length condition
      if !value_min_length.nil? || !value_max_length.nil?
        # Define constraint part
        constraint_part = (field/:pattern)

        # Unless value_min is nil?
        unless value_min_length.nil?
          # Kind of condition => MIN-LENGTH => PADDING MODE
          kind = 'min'

          # Define length condition
          length_condition = value_min_length
        else
          # Kind of condition => MAX-LENGTH => TRUNCATE MODE
          kind = 'max'

          # Define length condition
          length_condition = value_max_length
        end

        # Process constraint on the value
        result = process_constraint_length_condition(value,length_condition,constraint_part, kind)
      else
        # No Length condition
        # Define result equal to value
        result = value
      end
    end

    # Return value for this field
    result
  end

  # Process a constraint field
  # value : Applying constraint value
  # length_condition : number of (MIN|MAX) length for "value"
  # constraint : Constraint XML Node
  # kind : max or min
  def process_constraint_length_condition(value,length_condition, constraint, kind)
    # Instanciate variable
    result = ''

    # If Constraint is present
    unless constraint.nil?
      # Constraint is to perfrom a padding (left or right) with a character or truncate (left or right) the value
      value_constraint_character = constraint.at("value").inner_html.to_s unless constraint.at("value").nil?
      position_pattern = constraint.at("position").inner_html.to_s unless constraint.at("position").nil?
    end

    # If kind is max
    if kind.eql?('max')
      # If the length condition is not respected
      if value.length > length_condition.to_i
        # Truncate the value (left or right)
        result = process_max_condition_on_value(value,length_condition, position_pattern)
      else
        # Condition MAX is respected
        result = value
      end
    else
      # Kind is Min
      #
      # MIN is different than MAX
      # MIN Check the minimum character
      # If the length condition is not respected
      if value.length <= length_condition.to_i
        result = process_min_condition_on_value(value,length_condition, value_constraint_character, position_pattern)
      else
        # Condition MIN is respected
        result = value
      end
    end

    # Return
    result
  end

  # Process MIN condition on value
  def process_min_condition_on_value(value, min_length, padding_character, position_pattern)
    # Instanciate variable
    result = value
    required_character = 0

    # Count the number of times needed to pass the condition
    required_character = min_length.to_i - value.length

    # If they don t have position_padding
    if position_pattern.nil?
      # Use default position_padding
      position_pattern = "right"
    end

    # Perform truncate (LEFT or RIGHT)
    case position_pattern
      when "left" then required_character.to_i.times { result = padding_character + result }
      when "right" then required_character.to_i.times { result += padding_character }
    end

    # Return result
    result
  end

  # Process MAX condition on value
  def process_max_condition_on_value(value, max_length, position_pattern)
    # Instanciate variable
    result = ''

    # If they don t have position_padding
    if position_pattern.nil?
      # Use default position_padding
      position_pattern = "right"
    end

    # Perform truncate (LEFT or RIGHT)
    case position_pattern
      when "left" then result = value[max_length, (value.length-1)]
      when "right" then result = value[0, max_length]
    end

    # Return result
    return result
  end

  # Process a padding field
  def process_field_padding(field)
    # Instanciate variable
    result = ''

    # Retrieve required variable
    max_i = field.at("length").inner_html.to_i
    value = field.at("value").inner_html.to_s

    max_i.times { result += value}

    result
  end
end
