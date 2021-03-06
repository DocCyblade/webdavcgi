########################################################################
# (C) ZE CMS, Humboldt-Universitaet zu Berlin
# Written 2016 by Daniel Rohde <d.rohde@cms.hu-berlin.de>
#########################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#########################################################################

package Requests::OPTIONS;

use strict;
use warnings;

our $VERSION = '2.0';

use base qw( Requests::Request );

use DefaultConfig qw( $PATH_TRANSLATED $ENABLE_SEARCH );
use HTTPHelper qw( print_header_and_content get_dav_header get_supported_methods get_mime_type );

sub handle {
    my ($self)  = @_;
    my $cgi     = $self->{cgi};
    my $backend = $self->{backend};
    my $pt      = $PATH_TRANSLATED;
    $self->debug("HTTP_OPTIONS: $pt");
    $self->{event}->broadcast( 'OPTIONS', { file => $pt } );
    if ( !$backend->exists($pt) ) {
        return print_header_and_content('404 Not Found');
    }
    my $type =
      $backend->isDir($pt)
      ? 'httpd/unix-directory'
      : get_mime_type($pt);
    my $methods = join ', ', @{ get_supported_methods($backend, $pt) };
    my %params;
    if ($methods) {
        %params = (
            %params,
            'DAV'                      => get_dav_header(),
            'MS-Author-Via'            => 'DAV',
            'Allow'                    => $methods,
            'Public'                   => $methods,
            'DocumentManagementServer' => 'Properties Schema',
        );
        if ($ENABLE_SEARCH) {
            $params{DALS} = '<DAV:basicsearch>';
        }
    }
    return print_header_and_content( '200 OK', $type, q{}, \%params );
}
1;
