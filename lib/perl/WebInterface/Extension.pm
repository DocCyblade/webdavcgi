#########################################################################
# (C) ZE CMS, Humboldt-Universitaet zu Berlin
# Written 2010-2016 by Daniel Rohde <d.rohde@cms.hu-berlin.de>
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

package WebInterface::Extension;

use strict;
use warnings;

our $VERSION = '2.0';

use base qw( WebInterface::Common );

use DefaultConfig qw( $INSTALL_BASE $VHTDOCS %EXTENSION_CONFIG $CONFIG );

sub new {
    my ( $class, $hookreg, $extensionname ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{EXTENSION} = $extensionname;
    $self->{config}    = $CONFIG;
    $self->SUPER::init();
    return $self->init($hookreg);
}

sub init {
    my ( $self, $hookreg ) = @_;
    $self->SUPER::init();
    return $self;
}

sub get_location {
    my ( $self, $extension, $file ) = @_;
    return
        $INSTALL_BASE
      . 'lib/perl/WebInterface/Extension/'
      . $extension . q{/}
      . $file;
}

sub get_uri {
    my ( $self, $extension, $file ) = @_;
    my $vbase = $self->get_vbase();
    $vbase .= $vbase !~ /\/$/xms ? q{/} : q{};
    return $vbase . $VHTDOCS . '_EXTENSION(' . $extension . ')_/' . $file;
}

sub handle_hook_javascript {
    my ( $self, $config, $params ) = @_;
    return
        q@<script src="@
      . $self->get_uri( $self->{EXTENSION}, $params->{file} // 'htdocs/script.min.js' )
      . q@"></script>@;
}

sub handle_hook_css {
    my ( $self, $config, $params ) = @_;
    return
      q@<link rel="stylesheet" type="text/css" href="@
      . $self->get_uri( $self->{EXTENSION}, $params->{file} // 'htdocs/style.min.css' ) . q@">@;
}

sub handle_hook_locales {
    my ( $self, $config, $params) = @_;
    return $self->get_location( $self->{EXTENSION}, $params->{file} // 'locale/locale' );
}

sub handle_apps_hook {
    my ( $self, @args ) = @_;
    my ( $cgi, $action, $label, $title, $href ) = @args;
    return $cgi->li(
        { -title => $self->tl( $title // $label ) },
        $cgi->a(
            { -class => "action $action", -href => $href ? $href : q{#} },
            $cgi->span( { -class => 'label' }, $self->tl($label) )
        )
    );
}

sub handle_settings_hook {
    my ( $self, $settings ) = @_;
    my $ret = q{};
    if ( ref($settings) eq 'ARRAY' ) {
        foreach my $setting ( @{$settings} ) {
            $ret .= $self->handle_settings_hook($setting);
        }
    }
    elsif ( ref($settings) eq 'HASH' ) {
        foreach my $setting (
            sort {
                defined $settings->{$a}{order}
                  ? $settings->{$a}{order} <=> $settings->{$b}{order}
                  : $a cmp $b
            } keys %{$settings}
          )
        {
            my $ar     = $settings->{$setting};
            my $s      = 'settings.' . $setting;
            my %labels = map { $_ => $self->tl($_) } @{$ar};
            $ret .= $self->{cgi}->Tr(
                $self->{cgi}->td( $self->tl($s) )
                  . $self->{cgi}->td(
                    $self->{cgi}->popup_menu(
                        -name    => $s,
                        -values  => $ar,
                        -labels  => { map { $_ => $self->tl($_) } @{$ar} },
                        -default => $self->{cgi}->cookie($s)
                          // $EXTENSION_CONFIG{ $self->{EXTENSION} }{$s}
                          // $ar->[0]
                    )
                  )
            );
        }
    }
    else {
        $ret .= $self->{cgi}->Tr(
            $self->{cgi}->td( $self->tl("settings.$settings") )
              . $self->{cgi}->td(
                $self->{cgi}->checkbox(
                    -name  => "settings.$settings",
                    -label => q{}
                )
              )
        );
    }
    return $ret;
}

sub handle {
    my ( $self, $hook, $config, $params ) = @_;
    require CGI::Carp;
    CGI::Carp::carp("Missing handler for $hook in $self->{EXTENSION}.");
    return 0;
}

sub config {
    my ( $self, $var, $default ) = @_;
    return $EXTENSION_CONFIG{ $self->{EXTENSION} }{$var} // $default;
}

sub read_template {
    my ( $self, $filename ) = @_;
    return $self->SUPER::read_template( $filename,
        $self->get_location( $self->{EXTENSION}, 'templates/' ) );
}

sub exec_template_function {
    my ( $self, $fn, $ru, $func, $param ) = @_;
    my $content;
    if ( $func eq 'extconfig' ) {
        $content = $self->config( $param, 0 ) // q{};
    }
    $content //=
      $self->SUPER::exec_template_function( $fn, $ru, $func, $param );
    return $content;
}
1;
