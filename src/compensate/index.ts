interface CompensateInput {
  orderId: string;
  error?: {
    Cause: string;
    Error: string;
  };
}

interface CompensateOutput {
  orderId: string;
  compensated: boolean;
  reason: string;
}

export const handler = async (event: CompensateInput): Promise<CompensateOutput> => {
  console.log("Compensating for orderId:", event.orderId, "error:", event.error);

  // logica di compensazione applicativa (es. rollback, notifica, ecc.)

  return {
    orderId: event.orderId,
    compensated: true,
    reason: event.error?.Error ?? "unknown",
  };
};
