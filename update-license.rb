require 'set'

# define how similar a license must be to be replaced
# (0.0: no similarity, 1.0: 100% similarity (word-wise)
LICENSE_SIMILARITY_THRESHOLD = 0.8

AUTHOR = "Michael Specht"
PACKAGE = "GPF"
START_YEAR = "2007"
END_YEAR = Time.now.strftime('%Y')
LICENSE = "LGPL"

$sourceExtensions = {
    '.rb'  => :pound,
    '.py'  => :pound,
    '.c'   => :cstyle,
    '.cpp' => :cstyle,
    '.h'   => :cstyle
}

$commentStyles = {
    :pound => {
        :start => '',
        :prefix => '#',
        :end => ''
    },
    :cstyle => {
        :start => '/*',
        :prefix => '',
        :end => '*/'
    }
}

LICENSE_TEXT = <<LICENSE_END
Copyright (c) #{START_YEAR}-#{END_YEAR} #{AUTHOR}

This file is part of #{PACKAGE}.

#{PACKAGE} is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

#{PACKAGE} is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with #{PACKAGE}.  If not, see <http://www.gnu.org/licenses/>.
LICENSE_END

# CommentReader:
# --------------
#         
# - read the first comment block, including all leading and trailing white space
# - 

class CommentReader
    def readFirstComment(path)
        extension = nil
        $sourceExtensions.keys.each do |ext|
            if path[-ext.size, ext.size] == ext
                extension = ext
                break
            end
        end
        tags = $commentStyles[$sourceExtensions[extension]]
        firstComment = ''
        started = false
        checkForCommentStart = true
        File::open(path, 'r') do |f|
            f.each_line do |line|
                started = true unless line.strip.empty?
                next unless started
                firstComment += line
                if checkForCommentStart
                    if line.include?(tags[:start])
                        checkForCommentStart = false
                    else
                        firstComment = ''
                        break
                    end
                end
                if line[0, tags[:prefix].size] != tags[:prefix]
                    break
                end
                if (!tags[:end].empty?) && (line.include?(tags[:end]))
                    break
                end
            end
        end
        return firstComment
    end
end

def extractWords(s)
    words = Set.new
    s.downcase.split(/\W/).each do |word|
        words << word if word =~ /[a-z]+/
    end
    words
end

def textSimilarity(a, b)
    wordsA = extractWords(a)
    wordsB = extractWords(b)
    return (wordsA & wordsB).size.to_f / (wordsA | wordsB).size.to_f
end

def wordwrap(as_String, ai_MaxLength = 70)
    lk_RegExp = Regexp.new('.{1,' + ai_MaxLength.to_s + '}(?:\s|\Z)')
    as_String.gsub(/\t/,"     ").gsub(lk_RegExp){($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}
end

def getLicense
    template = LICENSE.dup
    template.gsub!('General', 'Lesser General') if LICENSE == 'LGPL'
    wordwrap(eval('"' + template + '"'))
end

$license = getLicense

# firstComment = CommentReader.new.readFirstComment(ARGV.first)
# puts firstComment
# puts "similarity: #{textSimilarity($license, firstComment)}"

def updateLicense(path)
    puts "Checking #{path}..."
    content = File::read(path)
    firstComment = ''
    inComment = false
    File::open(path, 'r') do |f|
        f.each_line do |line|
            if line.include?('/*')
                inComment = true
            end
            firstComment += line if inComment
            if line.include?('*/') && inComment
                inComment = false
                break
            end
        end
    end
    firstComment = '' unless firstComment.downcase.include?('copyright')
    content = File::read(path)
    content.gsub!(firstComment, '') unless firstComment.empty?
    File::open(path, 'w') do |f|
        f.puts $license
        f.puts unless content[0, 1] == "\n"
        f.puts content
    end
end

if File::basename($0) == 'update-license.rb'
    if ARGV.empty?
        puts "Usage: ruby update-license.rb [path]"
        puts 
        puts "This will take all #{$sourceExtensions.keys.sort.join('/')} files and "
        puts "update or insert a (L)GPL license header according to the"
        puts "settings in this script, which are currently:"
        puts 
        puts "Package: #{PACKAGE}"
        puts "Author:  #{AUTHOR}"
        puts "Years:   #{START_YEAR} - #{END_YEAR}"
        puts "License: #{LICENSE}"
        puts
        puts "Be careful, this script overwrites all matching files, no "
        puts "questions asked. Therefore be sure to use it on a clean Git"
        puts "working directory and inspect the changes before commiting."
        exit
    end


    Dir[File::join(ARGV.first, '**', '*')].each do |path|
        isSourceFile = false
        $sourceExtensions.keys.sort.each { |x| isSourceFile = true if path[-x.size, x.size] == x }
        next unless isSourceFile
        updateLicense(path)
    end
end
