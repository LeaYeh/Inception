<?php

define( 'DOMAIN_NAME', getenv('DOMAIN_NAME') );
define( 'DB_NAME', getenv('MYSQL_DATABASE') );
define( 'DB_USER', getenv('MYSQL_USER') );
define( 'DB_PASSWORD', getenv('MYSQL_USER_PASSWORD') );
define( 'DB_HOST', 'db' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

define('AUTH_KEY',         '5Qa$ff|,Enb/rT1g-CODO3y* |gjN7:Sb:u.AgU/v<|uIPO+K;.|fHr -uuzNZRk');
define('SECURE_AUTH_KEY',  's [n<e>pmeO+pY$mKw1xd~XjJQqlgZ>!xr l^ TA]W%YMDD>g6)*W;p95.Ry763R');
define('LOGGED_IN_KEY',    '?_3H7qNi+ynrMun|p:U}gVy|Vp5D5lA}dfESIJz~x!?$7-?R,n}h?xjg-p+hLQJ1');
define('NONCE_KEY',        '!Z>G*.r5BQQyEJfDS<kbk*n?nzcQT-%sW^kg-mT]V-+9E~8mwr-Iw,=NH,oEmSdw');
define('AUTH_SALT',        'TPFHcI=-YuC(ryF*q&76bDj;f0f|N *|;EDIfyPuR^Bs%F1Lws-/f#*/_p%;3>-c');
define('SECURE_AUTH_SALT', '2+o(+Dq#,hxU5h1-VFvL/|:3(_it=@&5+R1W~ud+ST0=nSYyE3di+-VSq66GO}3=');
define('LOGGED_IN_SALT',   'uY{gZ_W^:oz+lXP?l|e}WinyKe-R%Mu+t>(+w}mWUt4&:|weo78c+^/a8aKUk`NC');
define('NONCE_SALT',       '5/d}e;hxhRCZTyU!;B]l=o:uFjHYh<;`GQKnMYhDON.zM>>2@/++gN~v7~dJD*Hz');

$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

define( 'WP_HOME', 'https://' . DOMAIN_NAME );
define( 'WP_SITEURL', 'https://' . DOMAIN_NAME );

define( 'FORCE_SSL_ADMIN', true );


if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
