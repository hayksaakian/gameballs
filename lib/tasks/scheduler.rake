desc "This task is called by the Heroku scheduler add-on"
task :update_counts => :environment do
  puts "Updating viewer counts..."
  Game.update_counts
  puts "All updates done."
end