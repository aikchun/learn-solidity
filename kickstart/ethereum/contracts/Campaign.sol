pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        address campaignAddress = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(campaignAddress);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint256 public minContribution;
    mapping(address => bool) public approvers;
    uint256 public approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function Campaign(uint256 minimum, address m) public {
        manager = m;
        minContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minContribution);
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string desc,
        uint256 val,
        address recip
    ) public restricted {
        Request memory request =
            Request({
                description: desc,
                value: val,
                recipient: recip,
                complete: false,
                approvalCount: 0
            });

        requests.push(request);
    }

    function approveRequest(uint256 index) public {
        Request storage request = requests[index];
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvalCount++;
        request.approvals[msg.sender] = true;
    }

    function finalizeRequest(uint256 index) public restricted {
        Request storage request = requests[index];
        require(!request.complete);

        require(request.approvalCount > (approversCount / 2));
        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            minContribution,
            this.balance,
            requests.length,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return requests.length;
    }
}
