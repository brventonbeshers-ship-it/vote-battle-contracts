import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";

describe("vote-dapp-stacks", () => {
  it("should return initial proposal count as zero", () => {
    const result = simnet.callReadOnlyFn(
      "vote-dapp-stacks",
      "get-proposal-count",
      [],
      simnet.deployer
    );
    expect(result.result).toBeOk(Cl.uint(0));
  });

  it("should return initial total votes as zero", () => {
    const result = simnet.callReadOnlyFn(
      "vote-dapp-stacks",
      "get-total-votes",
      [],
      simnet.deployer
    );
    expect(result.result).toBeOk(Cl.uint(0));
  });

  it("should return default user stats", () => {
    const result = simnet.callReadOnlyFn(
      "vote-dapp-stacks",
      "get-user-stats",
      [Cl.standardPrincipal(simnet.deployer)],
      simnet.deployer
    );
    expect(result.result).toBeOk(
      Cl.tuple({
        "votes-cast": Cl.uint(0),
        "proposals-created": Cl.uint(0),
      })
    );
  });

  it("should create a proposal", () => {
    const result = simnet.callPublicFn(
      "vote-dapp-stacks",
      "create-proposal",
      [
        Cl.stringUtf8("Best blockchain?"),
        Cl.list([
          Cl.stringUtf8("Stacks"),
          Cl.stringUtf8("Ethereum"),
          Cl.stringUtf8("Solana"),
        ]),
      ],
      simnet.deployer
    );
    expect(result.result).toBeOk(Cl.uint(0));
  });

  it("should increment proposal count after creation", () => {
    simnet.callPublicFn(
      "vote-dapp-stacks",
      "create-proposal",
      [
        Cl.stringUtf8("Test proposal"),
        Cl.list([Cl.stringUtf8("Yes"), Cl.stringUtf8("No")]),
      ],
      simnet.deployer
    );

    const result = simnet.callReadOnlyFn(
      "vote-dapp-stacks",
      "get-proposal-count",
      [],
      simnet.deployer
    );
    expect(result.result).toBeOk(Cl.uint(1));
  });

  it("should reject vote on non-existent proposal", () => {
    const result = simnet.callPublicFn(
      "vote-dapp-stacks",
      "vote",
      [Cl.uint(999), Cl.uint(0)],
      simnet.deployer
    );
    expect(result.result).toBeErr(Cl.uint(101));
  });

  it("should allow voting on a proposal", () => {
    simnet.callPublicFn(
      "vote-dapp-stacks",
      "create-proposal",
      [
        Cl.stringUtf8("Pick one"),
        Cl.list([Cl.stringUtf8("A"), Cl.stringUtf8("B")]),
      ],
      simnet.deployer
    );

    const wallet1 = simnet.getAccounts().get("wallet_1")!;
    const result = simnet.callPublicFn(
      "vote-dapp-stacks",
      "vote",
      [Cl.uint(0), Cl.uint(1)],
      wallet1
    );
    expect(result.result).toBeOk(Cl.bool(true));
  });

  it("should reject double voting", () => {
    simnet.callPublicFn(
      "vote-dapp-stacks",
      "create-proposal",
      [
        Cl.stringUtf8("Double vote test"),
        Cl.list([Cl.stringUtf8("X"), Cl.stringUtf8("Y")]),
      ],
      simnet.deployer
    );

    const wallet1 = simnet.getAccounts().get("wallet_1")!;
    simnet.callPublicFn("vote-dapp-stacks", "vote", [Cl.uint(0), Cl.uint(0)], wallet1);

    const result = simnet.callPublicFn(
      "vote-dapp-stacks",
      "vote",
      [Cl.uint(0), Cl.uint(1)],
      wallet1
    );
    expect(result.result).toBeErr(Cl.uint(102));
  });
});
