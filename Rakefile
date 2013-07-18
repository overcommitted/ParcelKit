task :default => [:'docs:generate']

namespace :docs do
  
  desc 'Generate documentation'
  task :generate => [:'docs:clean'] do
    appledoc_options = [
      '--output Documentation',
      '--project-name ParcelKit',
      '--project-company \'Overcommitted, LLC\'',
      '--company-id com.overcommittedapps',
      '--keep-intermediate-files',
      '--create-html',
      '--no-repeat-first-par',
      '--no-create-docset',
      '--no-merge-categories',
      '--verbose 3']
  
    puts `appledoc #{appledoc_options.join(' ')} ParcelKit/*.h`
  end

  desc 'Clean docs'
  task :clean do
    `rm -rf Documentation/*`
  end
  
end
