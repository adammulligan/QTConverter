require 'filemagic'
require 'streamio-ffmpeg'
require 'ruby-progressbar'

unless ARGV.length > 0
  puts "Supply a directory to scan for video files"
  exit(12)
end

directory = ARGV[0]

unless Dir.exists?(directory)
  puts "#{directory} does not exist"
  exit(1)
end

COMPATIBLE_TYPES = %w(
  application/mp4
  video/mp4
  video/vnd.objectvideo
  video/MP2T
  video/quicktime
  video/mpeg4
)

def mime_type file
  fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
  fm.file file
end

def video_files_only files
  files.delete_if { |file| !/video\//.match mime_type(file) }
end

def non_quicktime_files_only files
  video_files = video_files_only files

  video_files.delete_if do |file|
    COMPATIBLE_TYPES.include? mime_type(file)
  end
end

def video_files_in directory
  non_quicktime_files_only Dir.entries(directory)
end

Dir.chdir directory do
  video_files_in(directory).each do |video_file|
    progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t')

    movie = FFMPEG::Movie.new(video_file)
    movie.transcode("#{video_file}.mp4") do |progress|
      progressbar.progress = progress * 100
    end
  end
end
