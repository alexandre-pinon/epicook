pub type UnitType {
  Ml
  Cl
  Dl
  L
  G
  Kg
  Tsp
  Tbsp
  Cup
  Piece
  Pinch
  Bunch
  Clove
  Can
  Package
  Slice
  ToTaste
  Unit
}

pub fn to_string(cuisine_type: UnitType) -> String {
  case cuisine_type {
    Ml -> "ml"
    Cl -> "cl"
    Dl -> "dl"
    L -> "l"
    G -> "g"
    Kg -> "kg"
    Tsp -> "tsp"
    Tbsp -> "tbsp"
    Cup -> "cup"
    Piece -> "piece"
    Pinch -> "pinch"
    Bunch -> "bunch"
    Clove -> "clove"
    Can -> "can"
    Package -> "package"
    Slice -> "slice"
    ToTaste -> "to_taste"
    Unit -> "unit"
  }
}

pub fn from_string(cuisine_type: String) -> UnitType {
  case cuisine_type {
    "ml" -> Ml
    "cl" -> Cl
    "dl" -> Dl
    "l" -> L
    "g" -> G
    "kg" -> Kg
    "tsp" -> Tsp
    "tbsp" -> Tbsp
    "cup" -> Cup
    "piece" -> Piece
    "pinch" -> Pinch
    "bunch" -> Bunch
    "clove" -> Clove
    "can" -> Can
    "package" -> Package
    "slice" -> Slice
    "to_taste" -> ToTaste
    _ -> Unit
  }
}
