import { ChangeDetectorRef, Component, signal } from '@angular/core';
import { MGR_ABI } from '../mgr.abi';
import { ethers } from 'ethers';

@Component({
  selector: 'app-mgr-client',
  standalone: true,
  imports: [],
  templateUrl: './mgr-client.component.html',
  styleUrl: './mgr-client.component.scss',
})
export class MgrClientComponent {
  ethereum = (<any>window)['ethereum'];
  address = signal<string | null>(null);
  network = signal<number | null>(null);
  signer: ethers.providers.JsonRpcSigner | null = null;

  stage: 'nothing' | 'finalizing-1' | 'finalizing-2' | 'round' = 'nothing';
  registered = signal<boolean>(false);
  participants: { id: string; address: string; name: string }[] = [];

  MGRContract: ethers.Contract | null = null;
  MGRContractWithSigner: ethers.Contract | null = null;

  constructor(private changeDetector: ChangeDetectorRef) {
    this.ethereum.on('accountsChanged', (accounts: string[]) => {
      console.log('changing account', accounts);
      this.address.set(accounts[0]);
      this.changeDetector.detectChanges();
    });
    this.ethereum.on('chainChanged', (chain: any) => {
      console.log('chain changed to', chain);
      console.log('this is #', ethers.BigNumber.from(chain).toNumber());
      this.network.set(ethers.BigNumber.from(chain).toNumber());
      this.connect();
      this.changeDetector.detectChanges();
    });
    this.connect();
  }
  async connect() {
    const result = this.ethereum.request({ method: 'eth_requestAccounts' });
    console.log('connect result is', result);
    const accountList = await result;
    console.log('and resolves to', accountList);
    this.address.set(accountList[0]);

    const provider = new ethers.providers.Web3Provider(this.ethereum);
    await provider.send('eth_requestAccounts', []);
    this.signer = provider.getSigner();
    console.log('signer set to', this.signer);

    this.MGRContract = new ethers.Contract(
      '0x8f8dedd09E23E22E1555e9D2C25D7c7332291919',
      MGR_ABI,
      provider
    );
    this.MGRContractWithSigner = this.MGRContract.connect(this.signer);

    this.network.set((await provider.getNetwork()).chainId);

    // @TODO: Calculate remote gas cost
    // const remoteGas = await sdk.estimateGasFee('Avalanche', 'binance', 'AVAX');
    // console.log('estimated gas fee includes', remoteGas);
  }

  /**
   * Add yourself to the list of participants
   */
  async register(name: string) {
    if (!this.MGRContractWithSigner) return;
    this.MGRContractWithSigner['register'](name).then((tx: any) => {
      this.changeDetector.detectChanges();
      this.registered.set(true);
    });
  }
  async beginFinalization() {}
}
