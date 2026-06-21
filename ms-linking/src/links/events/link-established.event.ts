export type LinkEstablishedEvent = {
  eventType: "LinkEstablished";
  version: "1.0";
  timestamp: string;
  correlationId: string;
  producer: "ms-linking";
  data: {
    linkId: string;
    caregiverId: string;
    dependentId: string;
    dependentName: string;
    caregiverName: string;
  };
};
