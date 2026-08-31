/// Where an exported training zip is meant to end up (#744, design S3.2).
///
/// One constant, deliberately NOT duplicated across the seven `.arb` files:
/// the address appears in the copy through a placeholder, so changing it is a
/// one-line change here and no translation churn.
///
/// It is the maintainer's personal address for want of a project one; the
/// design records that as a point to revisit if a project address appears.
const String kAutoScorerExportContact = 'mathrb@gmail.com';
