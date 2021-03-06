# frozen_string_literal: true
require "English"
require "kennel"

namespace :kennel do
  desc "Ensure there are no uncommited changes that would be hidden from PR reviewers"
  task no_diff: :generate do
    result = `git status --porcelain`.strip
    abort "Diff found:\n#{result}\nrun `rake generate` and commit the diff to fix" unless result == ""
    abort "Error during diffing" unless $CHILD_STATUS.success?
  end

  desc "generate local definitions"
  task generate: :environment do
    Kennel.generate
  end

  # also generate parts so users see and commit updated generated automatically
  desc "show planned datadog changes"
  task plan: :generate do
    Kennel.plan
  end

  desc "update datadog"
  task update_datadog: :environment do
    Kennel.update
  end

  desc "update if this is a push to the default branch, otherwise plan (report to github with GITHUB_TOKEN)"
  task :travis do
    on_default_branch = (ENV["TRAVIS_BRANCH"] == (ENV["DEFAULT_BRANCH"] || "master"))
    is_push = (ENV["TRAVIS_PULL_REQUEST"] == "false")
    task_name =
      if on_default_branch && is_push
        "kennel:update_datadog"
      else
        "kennel:plan" # show plan in travis logs
      end

    Kennel::GithubReporter.report(ENV["GITHUB_TOKEN"]) do
      Rake::Task[task_name].invoke
    end
  end

  task :environment do
    require "kennel"
    gem "dotenv"
    require "dotenv"
    Dotenv.load
  end
end
