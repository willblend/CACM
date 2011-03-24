module CACM
  FULL_ACCESS_ROLES   = [:admin, :developer, :content_editors]
  ADMIN_ACCESS_ROLES  = [:admin, :developer]

  # These are full_text types of articles
  FULL_TEXT_TYPES = %w(index abstract fulltext pdf mp3 mp4 mov ps comments html htm txt digital_edition digital_library wmv external supplements)
  NON_DL_FULL_TEXT_TYPES = FULL_TEXT_TYPES-%w(digital_library)

  # These are supplement types
  QUICKTIME_SUPPLEMENTS = %w(mov mpeg mpg mp4 mp3)
  WINDOWS_SUPPLEMENTS = %w(avi wmv)
  SUPPLEMENT_TYPES = QUICKTIME_SUPPLEMENTS+WINDOWS_SUPPLEMENTS
  
  # These are publication id's for the different publications that CACM produces. There are articles of these types in the DL,
  # these constants are used to discern them when they are ingested so the articles can be assigned to the appropriate subclass. 
  PUB_ID = 'J79' # CACM magazine ID in DL
  QUEUE_ID = 'J882'
  CIE_ID = 'J912'
  CROSSROADS_ID = 'J190'
  E_LEARN_ID = 'J815'
  NET_WORKER_ID = 'J582'
  UBIQUITY_ID = 'J793'

  # define base sections of the site
  BLOGS_SECTION   = Section.find_or_create_by_name('Blogs')
  BLOG_CACM       = Section.find_or_create_by_name('Blog CACM')
  NEWS_SECTION    = Section.find_or_create_by_name('News')
  OPINION_SECTION = Section.find_or_create_by_name('Opinion')
  CAREERS_SECTION = Section.find_or_create_by_name('Careers')
  DEFAULT_SECTION_FOR_ROUTING = Section.find_or_create_by_name('Opinion')

  # define feeds
  DL_FEED_ID   = DLFeed.find_or_create_by_name(:name => 'From the Digital Library', :feed_type_id => 1).id
  CACM_FEED_ID = CacmFeed.find_or_create_by_name('Communications of the ACM').id
  BLOG_FEED_ID = ManualFeed.find_or_create_by_name("blog@CACM").id

  # For retrieval and other automated access
  ADMIN_USER = 'cacmadmin'
  ADMIN_PASS = 'notdoris'
  
  # Endeca config (these are test settings, overridden in local_config)
  ENDECA_HOST = 'acm26-15.acm.org'
  ENDECA_PORT = 15002
  
  # GSA and Mini IPs
  # also cacm.digitalpulp.com for priming the cache via linklint as an authenticated user (#644)
  CRAWLER_IPS = %w(63.118.7.43 63.118.7.44 10.0.0.19 209.176.7.203)
  # Filter out sessions where user-agent is a known crawler (#716)
  CRAWLER_AGENTS = /Googlebot|Slurp|msnbot|Teoma|Magnolia/i

  # TODO
  # consider adding a column for these in the subjects_keywords table,  
  # since these are based on the same mappings
  CCS_MAPPINGS = {
    # Subject.id => ccs_nodes
    1  => %w(I.2    I.2.10 I.2.9),                                            # artificial intelligence (and robotics)
    2  => %w(C.2    C.2.5  C.2.6   C.2.2   C.2.1  K.4.4),                     # communications / networking
    3  => %w(J.     J.1    J.2     J.1.h   J.7.d  J.5    J.6  J.3),           # computer applications
    4  => %w(C.     C.1    C.2),                                              # computer systems
    5  => %w(H.5    H.5.2),                                                   # computer-human interactions
    6  => %w(K.4    K.4.1  K.2     K.1     K.7),                              # computers and society
    7  => %w(E.     E.2    H.3.7   B.3.2),                                    # data / storage and retrieval
    10 => %w(K.3.2  K.3.1),                                                   # education
    11 => %w(J.7    J.5    K.8     K.8.0   I.2.1  I.3    J.7  I.3.7),         # entertainment
    12 => %w(B.     C.3    B.4.2   B.3.2   B.7),                              # hardware
    13 => %w(H.     H.2    H.3.7   K.6.1   K.9    K.6.1),                     # information systems
    14 => %w(K.5    K.4.1  K.5.1   K.7.4),                                    # legal aspects
    15 => %w(K.6    K.6.1  K.6.2   K.6.3   D.2.9  K.6.4  C.2.3),              # management
    16 => %w(B.8    C.4    D.2.8   H.3.4   D.2.4),                            # performance and reliability
    17 => %w(K.8    C.5.3  K.8.1   K.8.2   K.8.m),                            # personal computing
    19 => %w(H.3    H.3.3),                                                   # search
    20 => %w(E.2.3  D.4.6  K.6.5   C.2.0),                                    # security
    21 => %w(D.     D.2    D.3     D.2.3   D.2.8  D.4.8),                     # software
    22 => %w(F.     F.4.1  F.4.3)                                             # theory
  }
  
  RECAPTCHA_PUBLIC_KEY = '6Lfwr8ASAAAAAOHJ5XPA8UKrOT4y8jHTAWBNZIPb'
  RECAPTCHA_PRIVATE_KEY= '6Lfwr8ASAAAAAFxFQo5Wx0qs3eulq2m53UROIV6t'
end
