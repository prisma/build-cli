require_relative './src/build_context'
require_relative './src/command'
require_relative './src/commands'


bk_path = ENV['BUILDKITE_BUILD_CHECKOUT_PATH']
unless bk_path.nil?
  bk_path += "/server"
end

server_root = ENV['SERVER_ROOT'] || bk_path
unless !server_root.nil?
  raise "Can't determine server root path."
end

Dir.chdir(server_root)

git_fetch
context = BuildContext.new

unless context.should_build?
  puts "Nothing to do"
  exit 0
end

def print_usage
  puts """Prisma Build Tool
Usage: cli <subcommand>

Subcommands:
\tpipeline
\t\tRenders the pipeline based on the current build context and uploads it to buildkite.

\ttest <project> <connector>
\t\tTests given sbt project against the given connector.

\tbuild <tag>
\t\tBuilds and tags the docker image(s) on the current branch with the given tag. Additional tags to process are inferred from the given tag.
"""
end

if ARGV.length <= 0
  print_usage
  exit 1
end

command = ARGV[0]

case command
when "pipeline"
  upload_pipeline(context)

when "test"
  if ARGV.length <= 1
    print_usage
    exit 1
  end

  project = ARGV[1]
  if ARGV[2].nil?
    connector = :none
  else
    connector = ARGV[2].to_sym
  end

  test_project(context, project, connector)

when "build"
  if ARGV.length < 1
    print_usage
    exit 1
  end

  build_images(context, Tag.new(ARGV[1]))

else
  puts "Invalid command: #{command}"
  exit 1
end