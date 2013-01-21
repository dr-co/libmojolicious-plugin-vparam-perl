use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "Mojolicious::Plugin::Vparam",
    VERSION_FROM    => "lib/Mojolicious/Plugin/Vparam.pm",
    ABSTRACT_FROM   => "lib/Mojolicious/Plugin/Vparam.pm",
    MAKEFILE        => 'Makefile',
    LICENSE         => 'Perl',
    AUTHOR          => [
        'Dmitry E. Oboukhov <unera@debian.org>,',
        'Roman V. Nikolaev <rshadow@rambler.ru>',
    ],
    PREREQ_PM       => {
        'Mojo::Base'                    => 0,
        'DateTime'                      => 0,
        'DateTime::Format::DateParse'   => 0,
        'Mail::RFC822::Address'         => 0,
        'List::MoreUtils'               => 0,
    },
    META_MERGE => {
        resources => {
            homepage =>
                'https://github.com/dr-co/libmojolicious-plugin-vparam-perl',
            bugtracker =>
                'https://github.com/dr-co/libmojolicious-plugin-vparam-perl/issues',
        }
   }
);
