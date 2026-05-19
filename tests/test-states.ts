import {
  SFNClient,
  TestStateCommand,
  TestStateCommandInput,
  InspectionLevel,
} from "@aws-sdk/client-sfn";

const client = new SFNClient({ region: "eu-west-1" });

const STATE_MACHINE_ARN = "arn:aws:states:eu-west-1:416772749230:stateMachine:step-functions1-workflow";
const ROLE_ARN = "arn:aws:iam::416772749230:role/step-functions1-sfn";

// Definizione degli stati estratta dalla state machine
const STATES = {
  InvokeRestService: {
    Type: "Task",
    Resource: "arn:aws:lambda:eu-west-1:416772749230:function:step-functions1-invoke",
    Catch: [{ ErrorEquals: ["States.ALL"], ResultPath: "$.error", Next: "Compensate" }],
    Next: "Success",
  },
  Compensate: {
    Type: "Task",
    Resource: "arn:aws:lambda:eu-west-1:416772749230:function:step-functions1-compensate",
    Next: "Failure",
  },
};

async function testState(name: string, input: object, stateDefinition: object): Promise<void> {
  const params: TestStateCommandInput = {
    definition: JSON.stringify(stateDefinition),
    roleArn: ROLE_ARN,
    input: JSON.stringify(input),
    inspectionLevel: InspectionLevel.TRACE,
  };

  console.log(`\n--- Test: ${name} ---`);
  const result = await client.send(new TestStateCommand(params));
  console.log("Status:", result.status);
  console.log("Output:", result.output);
  if (result.error) console.log("Error:", result.error, result.cause);
  if (result.nextState) console.log("Next state:", result.nextState);
}

async function run(): Promise<void> {
  // Test 1: InvokeRestService → successo (Lambda risponde correttamente)
  await testState(
    "InvokeRestService - successo",
    { orderId: "123" },
    STATES.InvokeRestService
  );

  // Test 2: Compensate → esegue la compensazione con errore nell'input
  await testState(
    "Compensate - con errore",
    { orderId: "123", error: { Error: "RuntimeError", Cause: "Connection refused" } },
    STATES.Compensate
  );
}

run().catch(console.error);
