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

def non_quicktime_video_files_in directory
  non_quicktime_files_only Dir.entries(directory)
end

Dir.chdir directory do
  non_quicktime_video_files_in(directory).each do |video_file|
    progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t')

    video_file_without_extension = File.basename(video_file, File.extname(video_file))

    begin
      ffmpeg_options = "-acodec libfaac -b:a 128k -vcodec mpeg4 -b:v 1200k -flags +aic+mv4"

      movie = FFMPEG::Movie.new(video_file)
      movie.transcode("#{video_file_without_extension}.mp4", ffmpeg_options) do |progress|
        progress = progress * 100
        progress = 100 if progress > progressbar.total

        progressbar.progress = progress
      end

      FileUtils.mv video_file, "_old/#{video_file}"
    rescue FFMPEG::Error
      FileUtils.mv video_file, "_wont/#{video_file}"
      next
    end
  end
end
