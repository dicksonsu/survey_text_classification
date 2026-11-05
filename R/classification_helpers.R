# Initial rule-based classifications, adapted from the original Q22 script.
# These are machine-assigned predictions, not verified reference labels.

classify_q22 <- function(x) {
  junk <- paste0('^(', paste(c(
    'i have none', 'none', 'none really', 'none specifically', 'none in particular',
    'none at all', 'no one', 'no one in particular', 'nobody', 'nothing',
    'nothing in particular', 'nothing comes to mind', 'nothing really',
    'idk', 'unsure', 'not sure', 'im not sure', 'i dont know', 'dont know',
    'i do not know', 'cant remember', 'cannot remember', 'dont remember',
    'i dont remember', 'dont recall', 'i dont recall', 'i dont follow anyone',
    'i dont follow any', 'i do not follow anyone', 'i do not follow any',
    'i do not', 'i dont', 'no comment', 'cant think of any',
    'cannot think of any', 'i dont know the names', 'dont know their name',
    'dont know their names', 'dont know their specific names',
    'i cant remember their names', 'cant remember their names',
    'i dont remember the names off the top of my head', 'im not sure on names',
    'nobody i can think of', 'nothing really comes to mind'
  ), collapse = '|'), ')$')

  platforms <- paste0('^(', paste(c(
    'youtube', 'you tube', 'facebook', 'instagram', 'tiktok', 'tik tok',
    'twitter', 'x', 'snapchat', 'reddit', 'discord', 'twitch', 'podcasts?',
    'sports', 'gaming', 'gamers', 'fitness', 'fit', 'finance', 'music',
    'health', 'travel', 'technology', 'lifestyle', 'education', 'politics?',
    'political', 'wellness', 'true crime', 'youtubers', 'streamers',
    'cooking', 'fashion', 'parenting', 'masculinity', 'feminism',
    'social media', 'news', 'anime', 'artists', 'athletes', 'beauty',
    'celebrities', 'comedians', 'comedy', 'current events', 'entertainment',
    'entertaining', 'family', 'football', 'history', 'musicians',
    'sports players', 'sport', 'sports podcasts', 'travel vloggers',
    'wellbeing', 'motivation', 'actors', 'actresses'
  ), collapse = '|'), ')$')

  generic <- paste0('^(', paste(c(
    'anyone', 'a few', 'a few other ones too', 'a lot', 'a lot of people',
    'a lot of creators', 'a lot of different ones', 'a lot too many to name',
    'many others', 'too many to list', 'all of them', 'all that',
    'a little of everything', 'a whole lot of things', 'everything',
    'any .* influencer', 'any .* content', 'any gaming twitch person',
    'any music related content', 'any republican politician',
    'any democratic influencer'
  ), collapse = '|'), ')$')

  dplyr::case_when(
    is.na(x) | x == '' ~ 'junk',
    stringr::str_detect(x, junk) ~ 'junk',
    # Additional clear nonresponses
stringr::str_detect(
  x,
  "^(i cannot remember names|i do not follow anybody|i follow nobody)$"
) ~ "junk",
    stringr::str_detect(x, '^(a|n|na|n/a|999)$') ~ 'junk',
    stringr::str_detect(x, '^(myself|good)$') ~ 'mixed_or_needs_review',
    stringr::str_detect(x, '\\b(none|no one|nobody|nothing|dont know|not sure|cant remember|cannot remember|dont remember|dont recall|i dont follow|i do not follow|cant think of any|cannot think of any)\\b') &
      stringr::str_count(x, '\\S+') >= 4 ~ 'mixed_or_needs_review',
    stringr::str_detect(x, '\\b(influencers?|content creators?|creators?|podcasts?|people) like\\s+') ~ 'mixed_or_needs_review',
    # Generic descriptions without identifiable named creators

# Unspecified groups of people or creators
stringr::str_detect(
  x,
  "^(a few|some)\\s+(finance people|people|basketball players|on social media|on twitch)$"
) ~ "generic_nonentity",

# Generic references to platforms, topics, or formats
stringr::str_detect(
  x,
  "^(researchers on youtube|a podcast about science|a sports podcast|mostly fitness videos|the news|podcast shows|nba highlights)$"
) ~ "platform_or_topic",
    stringr::str_detect(x, '^(espn|nfl|barstool|jre|daily wire|cnn)$') ~ 'named_source',
    stringr::str_detect(x, '\\b(podcast|show|news|journal|times|daily|radio|network|channel)\\b') &
      stringr::str_count(x, '\\S+') >= 2 ~ 'named_source',
    stringr::str_detect(x, '\\binfluencers?\\b') ~ 'platform_or_topic',
    stringr::str_detect(x, platforms) ~ 'platform_or_topic',
    stringr::str_detect(x, generic) ~ 'generic_nonentity',
    stringr::str_detect(x, '^(content\\s+)?creators?$') ~ 'platform_or_topic',
    stringr::str_detect(x, '\\b[a-z]+\\s+(content\\s+)?creators?\\b') ~ 'platform_or_topic',
    TRUE ~ 'entity'
  )
}
