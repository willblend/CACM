module DP
  ::Haml::Template.options = { :autoclose => ['meta','img','link','br','hr','input','col','area', 'param'] }

  DATE_TIME_FORMATS = {
    :iso8601     => '%Y-%m-%d',
    :time        => '%I:%M %p',
    :date        => '%B %e, %Y',
    :abbr_date   => '%b %e, %Y',
    :mdy         => '%m/%d/%Y',
    :mdy_time    => '%m/%d/%Y @ %I:%M %p',
    :mdy_short   => '%m/%d/%y',
    :long        => '%B %e, %Y at %I:%M %p',
    :full        => '%A %B %e, %Y at %I:%M %p %Z',
    :calendar    => "%B %Y",
    :month       => "%B"
  }

  WIN1252_CHAR_MAP = {
    128 => "&#8364;",  # euro symbol                      &euro;    \u20AC
    # nothing at 129
    130 => "&#8218;",  # low single curved quote, right   &sbquo;   \u201A
    131 => "&#402;",   # "small letter F with hook"       (n/a)     \u0192
    132 => "&#8222;",  # low double curved quote, right   &bdquo;   \u201E
    133 => "&#8230;",  # horizontal ellipsis              &hellip;  \u2026
    134 => "&#8224;",  # dagger                           &dagger;  \u2020
    135 => "&#8225;",  # double dagger                    &Dagger;  \u2021
    136 => "&#710;",   # circumflex                       &circ;    \u02C6
    137 => "&#8240;",  # per mille                        &permil;  \u2030
    138 => "&#352;",   # capital S with caron             &Scaron;  \u0160
    139 => "&#8249;",  # left single angle bracket        &lsaquo;  \u2039
    140 => "&#338;",   # capital ligature OE              &OElig;   \u0152
    # nothing at 141
    142 => "&#381;",   # capital Z with caron             (n/a)     \u017D
    # nothing at 143
    # nothing at 144
    145 => "&#8216;",  # left single quote                &lsquo;   \u2018
    146 => "&#8217;",  # right single quote               &rsquo;   \u2019
    147 => "&#8220;",  # left double quote                &ldquo;   \u201C
    148 => "&#8221;",  # right double quote               &rdquo;   \u201D
    149 => "&#8226;",  # bullet                           &bull;    \u2022
    150 => "&#8211;",  # endash                           &ndash;   \u2013
    151 => "&#8212;",  # emdash                           &mdash;   \u2014
    152 => "&#732;",   # tilde                            &tilde;   \u02DC
    153 => "&#8482;",  # trademark                        &trade;   \u2122
    154 => "&#353;",   # small S with caron               &scaron;  \u0161
    155 => "&#8250;",  # right single angle bracket       &rsaquo;  \u203A
    156 => "&#339;",   # small ligature OE                &oelig;   \u0153
    # nothing at 157
    158 => "&#382;",   # small Z with caron               (n/a)     \u017E
    159 => "&#376;"    # capital Y with diaeresis         &Yuml;    \u0178
  }

  module REGEXP
    EMAIL = /^([\w\.!#\$%\-+.]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+)$/i
    URL   = %r{ (https?://)                       # protocol
                       (
                         [-\w]+                   # subdomain or domain
                         (?:\.[-\w]+)*            # remaining subdomains or domain
                         (?::\d+)?                # port
                         (?:/(?:(?:[~\w\+%-]|(?:[,.;:][^\s$]))+)?)* # path
                         (?:\?[\w\+%&=.;-]+)?     # query string
                         (?:\#[\w\-]*)?           # trailing anchor
                       ) 
                    }x
  end
end

ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(DP::DATE_TIME_FORMATS)
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(DP::DATE_TIME_FORMATS)
