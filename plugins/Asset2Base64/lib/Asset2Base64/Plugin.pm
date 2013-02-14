package Asset2Base64::Plugin;
use strict;
use MIME::Base64;

sub _hdlr_asset_thumbnail_file {
    my ( $ctx, $args ) = @_;
    my $asset = $ctx->stash( 'asset' )
        or return $ctx->_no_asset_error();
    return '' unless $asset->has_thumbnail;
    my %arg;
    foreach ( keys %$args ) {
        $arg{ $_ } = $args->{ $_ };
    }
    $arg{ Width }  = $args->{ width }  if $args->{ width };
    $arg{ Height } = $args->{ height } if $args->{ height };
    $arg{ Scale }  = $args->{ scale }  if $args->{ scale };
    $arg{ Square } = $args->{ square } if $args->{ square };
    my ( $file, $w, $h ) = $asset->thumbnail_file( %arg );
    return $file || '';
}

sub _filter_convert2base64 {
    my $src = shift;
    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    if ( $fmgr->exists( $src ) ) {
        require MT::Session;
        require Digest::MD5;
        my $id = 'base64:' . Digest::MD5::md5_hex( $src );
        my $cache = MT::Session->get_by_key( { id => $id, kind => 'B6' } );
        if ( my $data = $cache->data ) {
            my $update = ( stat( $src ) )[9];
            if ( $cache->start < $update ) {
            } else {
                return $data;
            }
        }
        my $data = $fmgr->get_data( $src, 'upload' );
        my $out = encode_base64( $data, '' );
        $cache->data( $out );
        $cache->start( time );
        $cache->save or die $cache->errstr;
        return $out;
    }
    return '';
}

1;