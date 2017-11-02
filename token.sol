pragma solidity ^0.4.15;

/*
This contract defines the admin functions.
Este contrato implementa as funções de administrador
*/
contract admined {
  address public admin;

  function admined() public {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _; /* Continue the function | Continua a função */
  }

  /*
  This function transfers the administration to another person.
  Esta função transfere os privilégios de admin para outra pessoa.
  */
  function transferAdmin(address newAdmin) onlyAdmin {
    admin = newAdmin;
  }
}

contract Token {

  /* This is a vector of all balances. | Vetor com todos os balanços dos endereços. */
  mapping (address => uint256) public balanceOf;

  /* Name of the token. | Nome da moeda. */
  string public name;

  /* Symbol of the token (E.g.: BTC, BCH). | Simbolo da moeda (Ex: BTC, BCH). */
  string public symbol;

  /* How many decimals. | Quantas casas após a vírgula. */
  uint8 public decimal;

  /* How many tokens there is. | Quantos tokens existem. */
  uint256 public totalSupply;

  /* Transfer event that anounces to the network a new transfer between accounts,
  the indexed keyword allows to search for this event by these parameters as filters.

  Evento que anuncia na rede uma transferência entre contas, a palavra reservada
  'indexed' indica que pode-se user os parâmetros como filtro para uma busca. */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /* Constructor, same name of the contract is mandatory.
  Construtor, tem que receber o mesmo nome do contrato. */
  function Token(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) {

    /* Whoever deploys this contract gets all the coins first.
    Quem fizer o deploy recebe todos os tokens inicialmente. */
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    decimal = decimalUnits;
    name = tokenName;
    symbol = tokenSymbol;
  }

  /* This function will tranfer tokens to the '_to' address.
  Esta função permite transferir tokens  para o endereço '_to'. */
  function transfer(address _to, uint256 _value) {


  /* Checks if sender has enough balance to transfer.
  Verifica se existe saldo suficiente para transferir. */
  if(balanceOf[msg.sender] < _value) revert();

  /* If true, that means an overflow happened.
  Se verdadeiro indica um overflow no sistema. */
  if(balanceOf[_to] + _value < balanceOf[_to]) revert();

  balanceOf[msg.sender] -= _value;
  balanceOf[_to] += _value;

  /* Announces the transfer event.
  Anuncia o evento de transferencia. */
  Transfer(msg.sender, _to, _value);
  }
}

contract AssetToken is admined, Token {
  function AssetToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin)
  Token(initialSupply, tokenName, tokenSymbol, decimalUnits) {
    totalSupply = initialSupply;

    /* If an admin is provided, then...
    Se foi fornecido um admin, então... */
    if(centralAdmin != 0) {
      admin = centralAdmin; /* Is the new admin. | É o novo admin .*/
    } else {
      admin = msg.sender;
    }

    balanceOf[admin] = initialSupply;
    totalSupply = initialSupply;
  }

  /* This function creates moke tokens.
  Esta função cria mais tokens. */
  function mintTokens(address target, uint256 mintedAmount) onlyAdmin {
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;

    /* Publishes on the network the event that this smart contract received
    the mintedAmout and then that it was transfered to the target address.

    Publica na rede o evento que este contrato recebeu os novos tokens e em seguida
    os transferiu para a conta de destino. */
    Transfer(0, this, mintedAmount);
    Transfer(this, target, mintedAmount);
  }

  /* If crowdsale has limited supply use transfer function, if not use mintTokens.
  Se a ICO tiver quantidade ilimitada, use a função mintTokens, se não, transfer. */
  function transfer(address _to, uint256 _value) {

    if(balanceOf[msg.sender] < 0) revert();
    if(balanceOf[msg.sender] < _value) revert();
    if(balanceOf[_to] + _value < balanceOf[_to]) revert();

    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    Transfer(msg.sender, _to, _value);

  }
}
