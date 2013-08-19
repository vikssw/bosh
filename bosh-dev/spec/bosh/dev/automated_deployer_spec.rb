require 'spec_helper'

require 'bosh/dev/automated_deployer'

module Bosh::Dev
  describe AutomatedDeployer do
    let(:target) { 'micro.target.example.com' }
    let(:username) { 'user' }
    let(:password) { 'password' }

    let(:environment) { 'test_env' }
    let(:stemcell_path) { '/tmp/stemcell.tgz' }
    let(:release_path) { '/tmp/release.tgz' }
    let(:repository_path) { '/tmp/repo/' }

    let(:cli) { instance_double('Bosh::Dev::BoshCliSession').as_null_object }
    let(:deployments_repository) { instance_double('Bosh::Dev::Aws::DeploymentsRepository', path: repository_path, clone_or_update!: nil) }
    let(:build_number) { '123' }
    let(:artifacts_downloader) { instance_double('Bosh::Dev::ArtifactsDownloader') }

    subject(:deployer) do
      AutomatedDeployer.new(target: target,
                            username: username,
                            password: password,
                            build_number: build_number,
                            environment: environment,
                            deployments_repository: deployments_repository,
                            artifacts_downloader: artifacts_downloader,
                            cli: cli)
    end

    describe '#deploy' do
      before do
        artifacts_downloader.stub(:download_release).with(build_number).and_return(release_path)
        artifacts_downloader.stub(:download_stemcell).with(build_number).and_return(stemcell_path)
      end

      def bosh_should_be_called_with(*args)
        cli.should_receive(:run_bosh).with(*args).ordered
      end

      it 'follows the normal deploy procedure' do
        bosh_should_be_called_with 'target micro.target.example.com'
        bosh_should_be_called_with 'login user password'
        bosh_should_be_called_with 'deployment /tmp/repo/test_env/deployments/bosh/bosh.yml'
        bosh_should_be_called_with 'upload stemcell /tmp/stemcell.tgz', ignore_failures: true
        bosh_should_be_called_with 'upload release /tmp/release.tgz', ignore_failures: true
        bosh_should_be_called_with 'deploy', debug_on_fail: true

        deployer.deploy
      end

      it 'clones a deployment repository' do
        deployments_repository.should_receive(:clone_or_update!)

        deployer.deploy
      end
    end
  end
end