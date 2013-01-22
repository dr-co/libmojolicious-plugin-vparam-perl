#Mojolicious::Plugin::Vparam

This module use simple paramters types str, int, email, bool, etc. to validate.
Instead of many other modules you not need add specific validation subs or
rules. Just set parameter type. But if you want sub or rule you can do it too.

```perl
# Get one parameter
my $param1 = $self->vparam('date' => 'datetime');
# Or more syntax
my $param2 = $self->vparam('page' => {type => 'int', default => 1});
# Or more simple syntax
my $param2 = $self->vparam('page' => 'int', default => 1);

# Get many parameters
my %params = $self->vparams(
  # Simple syntax
  name => 'str',
  password => qr{^\w{,32}$},
  myparam => sub {
    my ($self, $param) = @_;
    return ($param eq 'ok') ?1 :0;
  },

  # More syntax
  from => { type => 'date', default => '' },
  to => { type => 'date', default => '' },
  id => { type => 'int' },
  money => { regexp => qr{^\d+(?:\.\d{2})?$} },
  myparam => { post => sub {
  my ($self, $param) = @_;
  return ($param eq 'ok') ?1 :0;
  } },
  isa => { type => 'bool', default => 0 },
  );
  
  # Same as vparams but auto add some more params for table sorting/paging
  my %filters = $self->vsort(
  -sort => ['name', 'date', ...],

  ...
);

# Get a errors hash by params name
my %errors = $self->verrors;
```

#Authors

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

#Copyright

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
