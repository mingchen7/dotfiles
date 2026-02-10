require 'rake'

desc "install the dotfiles into user's home directory"
task :install do
  replace_all = ENV["REPLACE_ALL"] == "true"
  non_config_files = %w{Rakefile README.md LICENSE Session.vim linux_setup.sh autoenv neovim.rb claude}

  Dir['*'].each do |file|
    next if non_config_files.include? file
    next if file == "nvim"

    if File.exist?(File.join(ENV['HOME'], ".#{file}"))
      if File.identical? file, File.join(ENV['HOME'], ".#{file}")
        puts "identical ~/.#{file}"
      elsif replace_all
        replace_file(file)
      elsif ENV["SKIP_EXISTING"] == "true"
        next
      else
        print "overwrite ~/.#{file}? [ynaq]"
        case $stdin.gets.chomp
        when 'a'
          replace_all = true
          replace_file(file)
        when 'y'
          replace_file(file)
        when 'q'
          exit
        else
          puts "skipping ~/.#{file}"
        end
      end
    else
      link_file(file)
    end
  end

  Dir['nvim/*'].each do |file|
    if File.identical? file, File.join(ENV['HOME'], ".config/#{file}")
      puts "identical ~/.config/#{file}"
    else
      puts "linking #{file} to ~/.config/#{file}"
      system %Q{ln -s "$PWD/#{file}" "$HOME/.config/#{file}"}
    end
  end

  # Install Claude commands and skills
  system %Q{mkdir -p "$HOME/.claude"}

  Dir['claude/commands/*'].each do |file|
    target = File.join(ENV['HOME'], ".claude/commands", File.basename(file))
    system %Q{mkdir -p "$HOME/.claude/commands"}
    if File.identical? file, target
      puts "identical ~/.claude/commands/#{File.basename(file)}"
    else
      puts "linking #{file} to ~/.claude/commands/#{File.basename(file)}"
      system %Q{ln -s "$PWD/#{file}" "#{target}"}
    end
  end

  Dir['claude/skills/*'].each do |file|
    target = File.join(ENV['HOME'], ".claude/skills", File.basename(file))
    system %Q{mkdir -p "$HOME/.claude/skills"}
    if File.identical? file, target
      puts "identical ~/.claude/skills/#{File.basename(file)}"
    else
      puts "linking #{file} to ~/.claude/skills/#{File.basename(file)}"
      system %Q{ln -s "$PWD/#{file}" "#{target}"}
    end
  end
end

def replace_file(file)
  system %Q{rm -rf "$HOME/.#{file}"}
  link_file(file)
end

def link_file(file)
  puts "linking ~/.#{file}"
  system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
end
