export interface RobberyForm {
  personsInvolved: '1' | '2-3' | '4-5' | 'more-than-5' | 'unknown';
  weapon: boolean;
  stillInArea: boolean;
  fleeDirection: 'north' | 'south' | 'east' | 'west' | 'unknown';
}

export interface AccidentForm {
  injured: boolean;
  vehicleCount: number;
  blocksTraffic: boolean;
  medicalPresent: boolean;
}

export type ReportFormData = RobberyForm | AccidentForm | Record<string, unknown>;
