# Text preparation based on the original Q22 research script.
# Input: one row per respondent, with RESPID and Q22 columns.
# Output: one row per nonempty text mention, retaining original Q22 text.

normalize_q22 <- function(x) {
  x <- stringr::str_to_lower(x)
  x <- stringr::str_replace_all(x, 'fresh and fit', 'fresh_and_fit')
  x <- stringr::str_replace_all(x, '[^a-z0-9,/& ]', '')
  x <- stringr::str_replace_all(x, ' and ', ',')
  x <- stringr::str_replace_all(x, '/', ',')
  x <- stringr::str_squish(x)
  x <- stringr::str_replace_all(x, 'fresh_and_fit', 'fresh and fit')

  # Manual delimiter repairs transcribed from the original project script.
  # The replacements are dataset-specific, not general name recognition.
  repairs <- c(
    'joe rogan brad pitt' = 'joe rogan, brad pitt',
    'christiano ronaldo kylie jenner dewayne johnson' = 'christiano ronaldo, kylie jenner, dewayne johnson',
    'faze rug brawdis lamelo ball' = 'faze rug, brawdis, lamelo ball',
    'andrew huberman steven bartlett graham stephan mel robbins' = 'andrew huberman, steven bartlett, graham stephan, mel robbins',
    'asmongold shane gillis papa meat' = 'asmongold, shane gillis, papa meat',
    'brooklyn frost kala stephen curry ayesha curry wendy ortiz eve ortiz' = 'brooklyn frost, kala, stephen curry ayesha curry, wendy ortiz, eve ortiz',
    'bruno mars lebron james jamea harden elon musk mark zuckerberg' = 'bruno mars, lebron james, jamea harden, elon musk, mark zuckerberg',
    'canadian prepper lawrence odonnell' = 'canadian prepper, lawrence odonnell',
    'candice owens meghan kelly' = 'candice owens, meghan kelly',
    'connie addie mccracken mama karls jade amber' = 'connie, addie mccracken, mama karls, jade amber',
    'coryxkenshin ray william johnson' = 'coryxkenshin, ray william johnson',
    'danny mullen christina randall' = 'danny mullen, christina randall',
    'scott adams dave ramsay donald trump' = 'scott adams, dave ramsay, donald trump',
    'omar raja dave ramsey' = 'omar raja, dave ramsey',
    'earn your leisure higher learning with van lathan & rachel lindsay devale ellis hairston family kountry wayne' = 'earn your leisure, higher learning with van lathan & rachel lindsay, devale ellis, hairston family, kountry wayne',
    'gilbert arenas jeff teague' = 'gilbert arenas, jeff teague',
    'gordon ramsey kelly clarkson' = 'gordon ramsey, kelly clarkson',
    'adin ross kai cenat' = 'adin ross, kai cenat'
  )
  for (old in names(repairs)) {
  x <- stringr::str_replace_all(
    x,
    stringr::fixed(old),
    repairs[[old]]
  )
}

# Remove common introductory phrases
# before identifiable names or content descriptions.
x <- stringr::str_remove(
  x,
  "^(i (mostly )?(watch|follow|listen to))\\s+"
)

# Remove introductory wording before named sources.
x <- stringr::str_remove(
  x,
  "^i like podcasts such as\\s+"
)

# Preserve the platform and creator as separate mentions.
x <- stringr::str_replace(
  x,
  "^youtube creators like\\s+",
  "youtube,"
)

x <- stringr::str_squish(x)

x
  }

prepare_q22 <- function(data) {
  stopifnot(all(c('RESPID', 'Q22') %in% names(data)))
  if (anyDuplicated(data$RESPID)) stop('Input must have one row per RESPID')
  data |>
    dplyr::mutate(Q22_original = Q22,
                  Q22 = normalize_q22(Q22)) |>
    tidyr::separate_rows(Q22, sep = ',') |>
    dplyr::mutate(Q22 = stringr::str_squish(Q22)) |>
    dplyr::filter(!is.na(Q22), Q22 != '') |>
    dplyr::group_by(RESPID) |>
    dplyr::mutate(mention_number = dplyr::row_number()) |>
    dplyr::ungroup()
}
