pragma solidity ^0.4.8;

//-----------------------------------------------------------------------------------------------------------------
//-----------------------------MAIN CONTRACT-----------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------
contract TCI_admin {
	
//GLOBAL BASE PARAMETERS-------------------------------------------
	
	uint public compteur;
	address[] public invoiceAddressList;//lists the addresses of the conected clients
	uint public initTime;
	address scheduler = 0x26416b12610d26fd31d227456e9009270574038f; //TestNet only
	address[]  who;
	uint myWhoLength;
	address owner;
	
	modifier onlyBy1(address _from){//useful to enter invoices
		if (tx.origin != _from) throw;
		_;
	}
	modifier onlyBy2(address _from1, address _from2){//useful to check the invoice
		if (tx.origin != _from1 && tx.origin != _from2) throw;
		_;
	}
	
	
	
//------------------------------------------------------------------
	struct  Client{
		bytes32 name;
		address accountAddress;
	}
//-----------------------------------------------------------------------

//accounts-----------------------------------------------------------
	//associates an EOA address with a name
	mapping(bytes32=>address) names;
//--------------------------------------------------------------------------

//INVOICES-----------------------------------------------------------------------
	struct Invoice{
		bytes32 nameFrom;
		bytes32 nameTo;
		uint256 value;
		uint256 expiration_date;
		address from;
		address to;
		bool paidFro;
		bool paidTo;
	}
	
//associates each client with one or more invoices. They will enter their own address manually so that it is still accessible
	mapping(address=>Invoice[]) invoices;
	

	
//a list of the Clients TCI + name (useful to initiate an instance of TCI_client at the correct address)
	Client[] accountList;

//--------------------------------------------------------------------------------
//BUSINESS-------------------------------------------------------------------------
	struct Business{// if a company wants to do business with another
		bytes32 nameFrom;
		bytes32 nameTo;
		address from;
		address to;
	}
	
	//associates each client with one or more business proposal/opportunity/etc...
	mapping(address=>Business[]) buisiness;
	
//the next 2 functions will need to receive crypted content!!!
	
//MESSAGES------------------------------------------------------------------------

	
	
	

//--------------------------------------------------------------------------------
	
	

//CONSTRUCTOR---------------------------------------------------------------------
	function TCI_admin(){//fonction constructice obligatoire
		compteur=0;
		initTime = now;
		//stage = Stages.networkIni;
		owner=msg.sender;
		
	}
//--------------------------------------------------------------------------------
	
//a function that returns the TCI_client account address associated to a name
	function getAccount(Client[]  lc, bytes32  Name) internal returns (address acc){
		for (uint i=0; i<lc.length; i++){
			if (lc[i].name==Name){
				acc=lc[i].accountAddress;
			}
		}
	}
//a function that converts time in blocks
	
	
	function manualEntry(bytes32 you, bytes32 other, uint256 entry, uint256 exp, address t)
		/*atStage(Stages.safeEnter)*/
	{
		Invoice memory Inv ;//create a local Invoice structure that will contain the invoice info for ONE invoice
		Inv.nameFrom=you;
		Inv.nameTo=other;
		Inv.value=entry;
		Inv.expiration_date=exp;
		Inv.from=tx.origin;
		Inv.to=t;
		Inv.paidFro=false;
		Inv.paidTo=false;
		invoices[tx.origin].push(Inv);//add the nex invoice struct to the invoices mapping of invoice lists at the clients address
		invoiceAddressList.push(tx.origin);//that way we have an easy way of knowing who has entered the invoices
		names[you]=tx.origin;
		names[other]=t;
		compteur++;	
		
	}
	
	function wantsBusiness(bytes32 you, bytes32 other, address t){
		Business memory biz;
		biz.nameFrom = you;
		biz.nameTo = other;
		biz.from = tx.origin;
		biz.to = t;
	}
	
//a VERY BASIC function that "decides" who has chances of (not) getting paid
//returns the list of addresses of the people that could not be paid, and the length of that list
	function whoIsConcerned(address origin) public {
		uint l = invoices[origin].length;
		if (l<=who.length){
			for (myWhoLength=0; myWhoLength<l; myWhoLength++){
				who[myWhoLength]=invoices[origin][myWhoLength].to;
			}
		}
		else{
			for(myWhoLength=0; myWhoLength<who.length; myWhoLength++){
				who[myWhoLength]=invoices[origin][myWhoLength].to;
			}
			for(myWhoLength=who.length;myWhoLength<l; myWhoLength++){
				who.push(invoices[origin][myWhoLength].to);
			}
		}
		
				
	}

//saves that the person has paid, only accessible by him, and the other
//there needs to be the two confirmations for it to be valid
	function paiementConfirmation(bytes32 fro, bytes32 t) onlyBy2(names[fro],names[t]) {
		for (uint j=0; j<invoices[names[fro]].length; j++){
			if(invoices[names[fro]][j].to == names[t]){
				if (tx.origin==names[fro]){
					invoices[names[fro]][j].paidFro=true;
				}
				else if (tx.origin==names[t]){
					invoices[names[fro]][j].paidTo=true;
				}
			
			}
		}
	}

	
	//function callScheduler() onlyBy1(owner) /*atStage(Stages.safeEnter)*/{
		/*for (uint k=0; k<invoiceAddressList.length; k++){
			for (uint r=0; r<invoices[invoiceAddressList[k]].length; r++){
				//the 4-byte abi signature of the called function
				bytes4 sig = bytes4(sha3("checkFunction(invoiceList[k],r)"));
				//the targeted block
				//we use the expiration date by accessing the invoice of the list at the address "k" in the mapping
				uint targetBlock = block.number + blocksUntilTime(invoices[invoiceAddressList[k]][r].expiration_date );
				//the 4-byte signature of the scheduleCall function
				bytes4 scheduleCallSig = bytes4(sha3("scheduleCall(bytes4,uint256)"));
				//asks the Alarm Clock to create a "Call Contract"
				scheduler.call(scheduleCallSig,sig,targetBlock);
			}
		}
	}*/
	
//function used for ONE client, ONE invoice 
//used to send a message readable why EVERYONE
//I will need to implement a crypting system for the demo
	function checkFunction(bytes32 client, uint r)   {
		bytes32  _sir = invoices[names[client]][r].nameFrom;
		bytes32 _dest = invoices[names[client]][r].nameTo;
		
		bytes32   _him;
		address account;
		TCI_client con;
		whoIsConcerned(names[client]);
		
		
		if (invoices[names[client]][r].paidFro==true && invoices[names[client]][r].paidTo==true){

			for (uint k=0; k<myWhoLength; k++){
				_him = invoices[names[client]][k].nameTo;
				account=getAccount(accountList,_him);//get the TCI_client account linked to _him
				con=TCI_client(account);
				con.localCheck(now, "message for", _him, _sir, "has paid", _dest);
			}
		}
		else{
			for (uint m=0; m<myWhoLength; m++){
				_him = invoices[names[client]][m].nameTo;
				account=getAccount(accountList,_him);//get the TCI_client account linked to _him
				con=TCI_client(account);
				con.localCheck(now, "message for", _him, _sir, "hasn't paid", _dest);
			}
		}
		
	}
	
//------------CLIENT CONTRACT CREATION FUNCTION------------------------------------------------------------------
	
//a function that gathers the addresses of the client contracts
//User can access the name directly with the public global Name variable from the client contract
	function getNew(address enter, bytes32 Name){
		Client memory client;//need to create a Client struct before entering info in the list
		client.name=Name;
		client.accountAddress=enter;
		accountList.push(client);
		
	}

}

