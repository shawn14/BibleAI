#!/usr/bin/env ruby
# Rebuild the read-only resource from the provider's pinned XML using its own parser.
# Usage and source checksums are recorded in BibleAI/ScriptureIndex/NOTICE.txt.
gem 'bible_parser', '= 1.1.4'
require 'bible_parser'
require 'digest'
require 'sqlite3'
require 'tmpdir'

source_files = {
  'kjv' => ['eng-kjv.osis.xml', 'eeeae647fc28360ce47f9c0d5cc3b397b7fdd9913fe53dc9f44eb6deee50e253'],
  'web' => ['eng-web.usfx.xml', '5ffa2626f170a109a4a96afc90775c06f0821cb4ba81ed34e63663e085708d68']
}
book_ids = %w[
  GEN EXO LEV NUM DEU JOS JDG RUT 1SA 2SA 1KI 2KI 1CH 2CH EZR NEH EST JOB PSA PRO
  ECC SNG ISA JER LAM EZK DAN HOS JOL AMO OBA JON MIC NAM HAB ZEP HAG ZEC MAL MAT
  MRK LUK JHN ACT ROM 1CO 2CO GAL EPH PHP COL 1TH 2TH 1TI 2TI TIT PHM HEB JAS
  1PE 2PE 1JN 2JN 3JN JUD REV
]
ordinal = book_ids.each_with_index.map { |id, index| [id, index + 1] }.to_h
abort 'Usage: build-scripture-index.rb <upstream XML directory>' unless ARGV.length == 1
output = File.expand_path('../BibleAI/ScriptureIndex/scripture.sqlite3', __dir__)
Dir.mktmpdir('rebuild-', File.dirname(output)) do |tmp|
  path = File.join(tmp, 'scripture.sqlite3')
  db = SQLite3::Database.new(path)
  source_files.each do |edition, (filename, checksum)|
    file = File.join(ARGV.first, filename)
    abort "Wrong source file: #{filename}" unless Digest::SHA256.file(file).hexdigest == checksum
    db.execute("CREATE VIRTUAL TABLE #{edition} USING fts5(text, tokenize='unicode61')")
    db.transaction do
      db.prepare("INSERT INTO #{edition}(rowid, text) VALUES (?, ?)") do |insert|
        File.open(file) do |io|
          BibleParser.new(io).each_verse do |v|
            number = ordinal[v.book_id]
            next unless number
            text = v.text.split(/[[:space:]]+/).reject(&:empty?).join(' ')
            next if text.empty? # Five WEB references carry only a footnote in this source.
            raise "Invalid reference #{v}" unless (1..150).cover?(v.chapter_num) && (1..176).cover?(v.num)
            rowid = number * 1_000_000 + v.chapter_num * 1_000 + v.num
            insert.execute!(rowid, text)
          end
        end
      end
      db.execute("INSERT INTO #{edition}(#{edition}) VALUES ('optimize')")
    end
  end
  db.execute('VACUUM')
  db.close
  File.rename(path, output)
end
