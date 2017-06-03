Aip.config do |config|
  config.work_type: "default"
  config.metadata_file: "mets.xml"

  config.depositor: acollier@calstate.edu
  config.input_dir: /Users/acollier/Temp/drew/
  config.create_admin_sets: true

  config.exit_on_error: true

  # output_level: How much will be output to the shell while running
  # quiet - Nothing will be output
  # minimal - a running progress bar will be output
  # verbose - running progress text will be output
  config.output_level: 'verbose'

  config.include_thumbnail: false

  config.default_university: <ENTER UNIVERSITY BEING IMPORTED>
end
