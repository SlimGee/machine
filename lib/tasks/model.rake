namespace :model do
  desc "TODO"
  task infer: :environment do
    dc = DomainNameClassifier.new
    puts dc.predict("programafidelidadeitacard2.cf")
  end
end
