import https from "https";

interface InvokeInput {
  orderId: string;
}

interface InvokeOutput {
  orderId: string;
  status: string;
}

export const handler = async (event: InvokeInput): Promise<InvokeOutput> => {
  const url = process.env.REST_URL;
  if (!url) throw new Error("REST_URL environment variable is not set");

  const data = await httpGet(url);

  console.log("REST response:", data);

  return {
    orderId: event.orderId,
    status: "completed",
  };
};

function httpGet(url: string): Promise<unknown> {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let body = "";
      res.on("data", (chunk) => (body += chunk));
      res.on("end", () => resolve(JSON.parse(body)));
      res.on("error", reject);
    });
  });
}
