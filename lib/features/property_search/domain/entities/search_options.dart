// The fixed choices on the search form. Each apiValue is exactly what
// `POST /case` takes — the create accepts the display wording for titles and
// purposes, and stores them kebab-cased.

/// "Class of property". One per search.
enum PropertyClass {
  land('land', 'Land', 'Undeveloped'),
  building('building', 'Building', 'Residential'),
  commercial('commercial', 'Commercial', 'Office, Retail');

  const PropertyClass(this.apiValue, this.label, this.hint);

  final String apiValue;
  final String label;
  final String hint;
}

/// "Title the seller claims". Several may apply, except [notSure].
enum TitleType {
  certificateOfOccupancy('Certificate of Occupancy'),
  rightOfOccupancy('Right of Occupancy'),
  deedOfAssignment('Deed of Assignment'),
  powerOfAttorney('Power of Attorney'),
  notSure("Not sure / seller hasn't said");

  const TitleType(this.apiValue);

  final String apiValue;

  String get label => apiValue;
}

/// "Purpose of Inquiry". At least one.
enum InquiryPurpose {
  dueDiligence('Due Diligence', 'Verify ownership and property documents'),
  physicalInspection(
    'Physical Inspection',
    "Verify the property's physical condition and details",
  );

  const InquiryPurpose(this.apiValue, this.hint);

  final String apiValue;
  final String hint;

  String get label => apiValue;
}
