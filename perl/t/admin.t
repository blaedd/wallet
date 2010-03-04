#!/usr/bin/perl -w
#
# Tests for wallet administrative interface.
#
# Written by Russ Allbery <rra@stanford.edu>
# Copyright 2008, 2009, 2010 Board of Trustees, Leland Stanford Jr. University
#
# See LICENSE for licensing terms.

use Test::More tests => 16;

use Wallet::Admin;
use Wallet::Report;
use Wallet::Schema;
use Wallet::Server;

use lib 't/lib';
use Util;

# We test database setup in init.t, so just do the basic setup here.
db_setup;
my $admin = eval { Wallet::Admin->new };
is ($@, '', 'Wallet::Admin creation did not die');
ok ($admin->isa ('Wallet::Admin'), ' and returned the right class');
is ($admin->initialize ('admin@EXAMPLE.COM'), 1,
    ' and initialization succeeds');

# We have an empty database, so we should see no objects and one ACL.
my $report = Wallet::Report->new;
my @objects = $report->objects;
is (scalar (@objects), 0, 'No objects in the database');
is ($report->error, undef, ' and no error');
my @acls = $report->acls;
is (scalar (@acls), 1, 'One ACL in the database');
is ($acls[0][0], 1, ' and that is ACL ID 1');
is ($acls[0][1], 'ADMIN', ' with the right name');

# Register a base object so that we can create a simple object.
is ($admin->register_object ('base', 'Wallet::Object::Base'), 1,
    'Registering Wallet::Object::Base works');
is ($admin->register_object ('base', 'Wallet::Object::Base'), undef,
    ' and cannot be registered twice');
$server = eval { Wallet::Server->new ('admin@EXAMPLE.COM', 'localhost') };
is ($@, '', 'Creating a server instance did not die');
is ($server->create ('base', 'service/admin'), 1,
    ' and creating base:service/admin succeeds');

# Test registering a new ACL type.
is ($admin->register_verifier ('base', 'Wallet::ACL::Base'), 1,
    'Registering Wallet::ACL::Base works');
is ($admin->register_verifier ('base', 'Wallet::ACL::Base'), undef,
    ' and cannot be registered twice');
is ($server->acl_add ('ADMIN', 'base', 'foo'), 1,
    ' and adding a base ACL now works');

# Clean up.
is ($admin->destroy, 1, 'Destruction succeeds');
unlink 'wallet-db';
