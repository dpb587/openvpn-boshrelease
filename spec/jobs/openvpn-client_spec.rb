require 'rspec'
require 'json'
require 'bosh/template/test'

describe 'openvpn-client' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('openvpn-client') }
  let(:properties) { minimum_properties }
  let(:minimum_properties) do
    {
      'tls_client' => {
        'private_key' => 'fake-client-key',
        'certificate' => 'fake-client-cert',
      },
    }
  end
  let(:consumes) do
    [
      Bosh::Template::Test::Link.new(
        name: 'server',
        instances: [
          Bosh::Template::Test::LinkInstance.new(
            address: '1.openvpn.example.com',
          ),
          Bosh::Template::Test::LinkInstance.new(
            address: '2.openvpn.example.com',
          ),
        ],
        properties: {
          'port' => '1234',
          'protocol' => 'udp',
          'cipher' => 'AES-256-CBC',
          'tls_server' => {
            'ca' => 'fake-server-ca',
          },
        }
      )
    ]
  end

  describe 'bin/control' do
    let(:template) { job.template('bin/control') }
    let(:rendered_template) { template.render(properties, consumes: consumes) }

    it 'renders' do
      expect(rendered_template).to include '#!/bin/bash'
    end
  end

  describe 'etc/profile.ovpn' do
    let(:template) { job.template('etc/profile.ovpn') }
    let(:rendered_template) { template.render(properties, consumes: consumes) }

    describe 'default openvpn options' do
      it 'only uses expected options' do
        expect(rendered_template.scan(%r{^([^\s]+)}).flatten).to contain_exactly(
          "client",
          "writepid",
          "group",
          "user",
          "status",
          "dev",
          "persist-key",
          "persist-tun",
          "verb",
          "mute",
          "mute-replay-warnings",
          "nobind",
          "resolv-retry",
          "remote-random",
          "remote-cert-tls",
          "remote",
          "remote",
          "cipher",
          "tls-client",
          "<ca>",
          "fake-server-ca",
          "</ca>",
          "<cert>",
          "fake-client-cert",
          "</cert>",
          "<key>",
          "fake-client-key",
          "</key>",
        )
      end
    end

    context 'server link' do
      describe 'properties' do
        describe ['protocol', 'port'] do
          it 'is configurable' do
            expect(rendered_template).to match %r{^remote 1.openvpn.example.com 1234 udp$}
          end
        end

        describe 'tls_server' do
          describe 'ca' do
            it 'is configurable' do
              expect(rendered_template).to match %r{^<ca>\nfake-server-ca\n</ca>$}
            end
          end
        end

        describe 'tls_version_min' do
          before { consumes[0].properties['tls_version_min'] = 'fake-version-min' }

          it 'is configurable' do
            expect(rendered_template).to match %r{^tls-version-min fake-version-min$}
          end
        end

        describe 'tls_cipher' do
          before { consumes[0].properties['tls_cipher'] = 'fake-cipher' }

          it 'is configurable' do
            expect(rendered_template).to match %r{^tls-cipher fake-cipher$}
          end
        end

        describe 'tls_crypt' do
          before { consumes[0].properties['tls_crypt'] = 'fake-crypt' }

          it 'is configurable' do
            expect(rendered_template).to match %r{^<tls-crypt>\nfake-crypt\n</tls-crypt>$}
          end
        end
      end

      describe 'instances' do
        it 'supports multiple endpoints' do
          expect(rendered_template).to match %r{^remote 1.openvpn.example.com 1234 udp$}
          expect(rendered_template).to match %r{^remote 2.openvpn.example.com 1234 udp$}
        end
      end
    end

    context 'required properties' do
      describe 'tls_client' do
        context 'when missing' do
          before { properties.delete 'tls_client' }

          it 'errors' do
            expect { rendered_template }.to raise_error RuntimeError, "Missing properties: tls_client and/or username+password"
          end
        end

        describe 'certificate' do
          it 'is configurable' do
            expect(rendered_template).to match %r{<cert>\nfake-client-cert\n</cert>$}
          end
        end

        describe 'private_key' do
          it 'is configurable' do
            expect(rendered_template).to match %r{<key>\nfake-client-key\n</key>$}
          end
        end
      end
    end

    context 'defaulted properties' do
      describe 'device' do
        before { properties['device'] = 'tun123456789' }

        it 'is configurable' do
          expect(rendered_template).to match %r{^dev tun123456789$}
        end
      end

      describe 'extra_config' do
        before { properties['extra_config'] = "fake-option1 fake-value1\nfake-option2 fake-value2" }

        it 'is configurable' do
          expect(rendered_template).to match %r{^fake-option1 fake-value1$}
          expect(rendered_template).to match %r{^fake-option2 fake-value2$}
        end
      end

      describe 'extra_configs' do
        before { properties['extra_configs'] = ['fake-option1 fake-value1', 'fake-option2 fake-value2'] }

        it 'is configurable' do
          expect(rendered_template).to match %r{^fake-option1 fake-value1$}
          expect(rendered_template).to match %r{^fake-option2 fake-value2$}
        end
      end

      describe ['username', 'password'] do
        before do
          properties['username'] = 'fake-username'
          properties['password'] = 'fake-password'
        end

        it 'is configurable' do
          expect(rendered_template).to match %r{^auth-user-pass /var/vcap/jobs/openvpn-client/etc/user-pass$}
        end
      end
    end
  end

  describe 'etc/user-pass' do
    let(:template) { job.template('etc/user-pass') }
    let(:rendered_template) { template.render(properties, consumes: consumes) }

    it 'is empty by default' do
      expect(rendered_template).to eq("\n")
    end

    describe ['username', 'password'] do
      before do
        properties['username'] = 'fake-username'
        properties['password'] = 'fake-password'
      end

      it 'is configurable' do
        expect(rendered_template).to eq("fake-username\nfake-password\n")
      end
    end
  end
end
